// lib/pages/workout/workout_page.dart
//
// Fluxo por exercício:
//   1. Usuário vê o exercício atual, desempenho anterior e séries já salvas
//   2. Preenche peso + reps (+ lado se unilateral)
//   3. [Salvar Série] → salva no DB, incrementa série, inicia descanso
//   4. [Próximo →]   → vai ao próximo exercício (sem exigir série)
//   5. [Pular]       → pula sem registrar
//   6. Na última: [Finalizar] → dialog de resumo → volta ao Home

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/constants/equipment_options.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/rest_timer_provider.dart';
import '../../core/providers/progress_extended_provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';
//import '../setup/widgets/setup_page.dart';

// Registro local de uma série (exibição imediata, sem roundtrip)
class _SetEntry {
  final int serie;
  final double peso;
  final int reps;
  final String lado;
  final String? equipamento;
  final String? observacoes;
  _SetEntry({
    required this.serie,
    required this.peso,
    required this.reps,
    required this.lado,
    this.equipamento,
    this.observacoes,
  });
}

class WorkoutPage extends ConsumerStatefulWidget {
  final int dayId;
  final String dayName;
  final int sessionId;

  const WorkoutPage({
    super.key,
    required this.dayId,
    required this.dayName,
    required this.sessionId,
  });

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  // ── Exercise list ───────────────────────────────────────────────
  List<Exercise> _exercises = [];
  int _currentIndex = 0;
  bool _loading = true;

  // ── Set tracking ────────────────────────────────────────────────
  int _currentSerie = 1;
  final List<_SetEntry> _setsLogged = [];
  List<ExerciseLog> _prevLogs = []; // último treino deste exercício

  // ── Inputs ──────────────────────────────────────────────────────
  final _pesoCtrl = TextEditingController(text: '0');
  final _repsCtrl = TextEditingController(text: '10');
  final _obsCtrl = TextEditingController();
  String _lado = 'ambos';
  String? _equipamentoSelecionado;
  bool _executandoUnilateral = false;

  // ── Session timer ───────────────────────────────────────────────
  int _sessionSecs = 0;
  Timer? _sessionTimer;

  // ── Lifecycle ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _initSessionDuration().whenComplete(() {
      _startSessionTimer();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restTimerProvider.notifier).setInWorkoutPage(true);
    });
  }

  Future<void> _initSessionDuration() async {
    try {
      final db = ref.read(databaseProvider);
      final session = await (db.select(db.workoutSessions)
            ..where((s) => s.id.equals(widget.sessionId)))
          .getSingleOrNull();
      if (session != null) {
        final startTime = DateTime.tryParse(session.data);
        if (startTime != null) {
          final diff = DateTime.now().difference(startTime).inSeconds;
          if (mounted) {
            setState(() {
              _sessionSecs = diff >= 0 ? diff : 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar duracao da sessao: $e');
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    _obsCtrl.dispose();
    try {
      ref.read(restTimerProvider.notifier).setInWorkoutPage(false);
    } catch (_) {}
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────

  Future<void> _loadExercises() async {
    final exs =
        await ref.read(exerciseDaoProvider).getExercisesForDay(widget.dayId);
    
    int initialIndex = 0;
    try {
      final currentLogs = await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
      if (currentLogs.isNotEmpty) {
        final sortedLogs = List<ExerciseLog>.from(currentLogs)..sort((a, b) => a.id.compareTo(b.id));
        final lastLog = sortedLogs.last;
        final lastActiveId = lastLog.exerciseId;
        final idx = exs.indexWhere((e) => e.id == lastActiveId);
        if (idx != -1) {
          initialIndex = idx;
        }
      }
    } catch (e) {
      debugPrint('Erro ao restaurar indice do exercicio: $e');
    }

    setState(() {
      _exercises = exs;
      _currentIndex = initialIndex;
      _loading = false;
    });
    if (exs.isNotEmpty) await _loadExerciseContext();
  }

  Future<void> _loadExerciseContext() async {
    if (_exercises.isEmpty) return;
    final ex = _current;

    // Busca desempenho do último treino para pré-preencher os campos
    final prev = await ref.read(logDaoProvider).getLastLogsForExercise(ex.id);

    // Busca logs já realizados na sessão atual para este exercício
    final currentLogs =
        await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
    final exerciseSessionLogs =
        currentLogs.where((l) => l.exerciseId == ex.id).toList();

    setState(() {
      _prevLogs = prev;
      _currentSerie = exerciseSessionLogs.length + 1;
      _setsLogged.clear();
      _setsLogged.addAll(exerciseSessionLogs.map((l) => _SetEntry(
            serie: l.serie,
            peso: l.peso,
            reps: l.repeticoes,
            lado: l.lado,
            equipamento: l.equipamento,
            observacoes: l.observacoes,
          )));
      _lado = 'ambos';
      _executandoUnilateral = ex.isUnilateral;
      _equipamentoSelecionado = ex.equipamento;

      if (exerciseSessionLogs.isNotEmpty) {
        _pesoCtrl.text = exerciseSessionLogs.last.peso.toString();
        _repsCtrl.text = exerciseSessionLogs.last.repeticoes.toString();
      } else if (prev.isNotEmpty) {
        final totalPeso = prev.map((l) => l.peso).fold<double>(0.0, (a, b) => a + b);
        final totalReps = prev.map((l) => l.repeticoes).fold<int>(0, (a, b) => a + b);
        final avgPeso = totalPeso / prev.length;
        final avgReps = (totalReps / prev.length).round();

        final pesoStr = avgPeso % 1 == 0 
            ? avgPeso.toInt().toString() 
            : avgPeso.toStringAsFixed(1);

        _pesoCtrl.text = pesoStr;
        _repsCtrl.text = avgReps.toString();
      } else {
        _pesoCtrl.text = '0';
        _repsCtrl.text = '10';
      }
    });
  }

  // ── Timers ──────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sessionSecs++);
    });
  }

  void _startRestTimer(int seconds) {
    ref.read(restTimerProvider.notifier).startRest(
          seconds,
          dayId: widget.dayId,
          dayName: widget.dayName,
          sessionId: widget.sessionId,
        );
  }

  void _skipRest() {
    ref.read(restTimerProvider.notifier).cancelRest();
  }

  // ── Convenience getters ─────────────────────────────────────────

  Exercise get _current => _exercises[_currentIndex];
  bool get _isLast => _currentIndex >= _exercises.length - 1;

  // ── Actions ─────────────────────────────────────────────────────

  int? _obterSeriesEsperadas(String? volume) {
    if (volume == null || volume.isEmpty) return null;
    final regex = RegExp(r'^(\d+)', caseSensitive: false);
    final match = regex.firstMatch(volume.trim());
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  Future<void> _salvarSerie() async {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    final obs = _obsCtrl.text.trim();
    final logDao = ref.read(logDaoProvider);
    final now = DateTime.now().toIso8601String();
    final Value<String?> valueObs = obs.isNotEmpty ? Value<String?>(obs) : const Value<String?>.absent();

    if (_executandoUnilateral && _lado == 'ambos') {
      // Grava dois logs: esquerdo e direito
      for (final l in ['esquerdo', 'direito']) {
        await logDao.insertLog(ExerciseLogsCompanion.insert(
          exerciseId: _current.id,
          sessionId: widget.sessionId,
          data: now,
          peso: peso,
          repeticoes: reps,
          serie: Value(_currentSerie),
          lado: Value(l),
          equipamento: Value(_equipamentoSelecionado),
          observacoes: valueObs,
        ));
      }
    } else {
      await logDao.insertLog(ExerciseLogsCompanion.insert(
        exerciseId: _current.id,
        sessionId: widget.sessionId,
        data: now,
        peso: peso,
        repeticoes: reps,
        serie: Value(_currentSerie),
        lado: Value(_lado),
        equipamento: Value(_equipamentoSelecionado),
        observacoes: valueObs,
      ));
    }

    _obsCtrl.clear();

    AudioService().beep();

    setState(() {
      _setsLogged.add(_SetEntry(
        serie: _currentSerie,
        peso: peso,
        reps: reps,
        lado: _lado,
        equipamento: _equipamentoSelecionado,
        observacoes: obs.isNotEmpty ? obs : null,
      ));
      _currentSerie++;
    });

    _startRestTimer(_current.tempoDescansoSegundos);

    final expectedSets = _obterSeriesEsperadas(_current.volume);
    if (expectedSets != null && _setsLogged.length >= expectedSets) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você completou as $expectedSets séries recomendadas!'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'IR PARA O PRÓXIMO',
              textColor: AppColors.primaryLight,
              onPressed: () {
                _proximoExercicio();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _proximoExercicio() async {
    // Incrementa vezesFeito se ao menos uma série foi salva
    if (_setsLogged.isNotEmpty) {
      await ref.read(exerciseDaoProvider).incrementVezesFeito(_current.id);
    }

    if (_isLast) {
      await _confirmarFinalizarTreino();
    } else {
      setState(() {
        _currentIndex++;
      });
      await _loadExerciseContext();
    }
  }

  Future<void> _pularExercicio() async {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _exercises.length;
    });
    await _loadExerciseContext();
  }

  Future<void> _confirmarFinalizarTreino() async {
    final logDao = ref.read(logDaoProvider);
    final currentLogs = await logDao.getLogsForSession(widget.sessionId);
    final completedIds = currentLogs.map((l) => l.exerciseId).toSet();

    final List<MapEntry<int, Exercise>> uncompleted = [];
    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      if (!completedIds.contains(ex.id)) {
        uncompleted.add(MapEntry(i, ex));
      }
    }

    if (uncompleted.isEmpty) {
      await _finalizarTreino();
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Exercícios Pendentes'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Você ainda não registrou nenhuma série para os seguintes exercícios:',
                  style: TextStyle(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                ...uncompleted.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle,
                                size: 6, color: AppColors.warning),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value.nome,
                              style: const TextStyle(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                const Text(
                  'Deseja finalizar o treino mesmo assim ou voltar para realizá-los?',
                  style: TextStyle(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _finalizarTreino();
              },
              child: const Text(
                'Finalizar mesmo assim',
                style: TextStyle(color: AppColors.primaryLight),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final firstPending = uncompleted.first;
                setState(() {
                  _currentIndex = firstPending.key;
                });
                await _loadExerciseContext();
              },
              child: const Text('Revisar Pendentes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finalizarTreino() async {
    _sessionTimer?.cancel();
    _skipRest();

    double totalVolume = 0;
    int uniqueExercisesCount = 0;
    int totalSetsCount = 0;

    try {
      final allSessionLogs = await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
      totalVolume = allSessionLogs.fold<double>(0.0, (sum, log) => sum + (log.peso * log.repeticoes));
      uniqueExercisesCount = allSessionLogs.map((log) => log.exerciseId).toSet().length;
      totalSetsCount = allSessionLogs.map((log) => '${log.exerciseId}_${log.serie}').toSet().length;
    } catch (e) {
      debugPrint('Erro ao calcular estatísticas do treino: $e');
    }

    await ref
        .read(workoutDaoProvider)
        .finishSession(widget.sessionId, _sessionSecs);

    AudioService().workoutDone();

    if (!mounted) return;
    _showFinishDialog(
      totalVolume: totalVolume,
      uniqueExercises: uniqueExercisesCount,
      totalSets: totalSetsCount,
    );
  }

  void _showFinishDialog({
    required double totalVolume,
    required int uniqueExercises,
    required int totalSets,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              content: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.card.withOpacity(0.95),
                      AppColors.card.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing circular Trophy/Cup Container
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.orange.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Congratulations Text
                    const Text(
                      'TREINO CONCLUÍDO!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryLight,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mais um treino pra conta, Mete Marcha! 🔥',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 20),

                    // Stats Grid (2 columns x 2 rows)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.45,
                      children: [
                        _buildFinishStatCard(
                          icon: Icons.timer_rounded,
                          iconColor: Colors.blueAccent,
                          label: 'Duração',
                          value: WeekUtils.formatDuration(_sessionSecs),
                        ),
                        _buildFinishStatCard(
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.primaryLight,
                          label: 'Exercícios',
                          value: '$uniqueExercises',
                        ),
                        _buildFinishStatCard(
                          icon: Icons.view_headline_rounded,
                          iconColor: Colors.purpleAccent,
                          label: 'Séries',
                          value: '$totalSets',
                        ),
                        _buildFinishStatCard(
                          icon: Icons.flash_on_rounded,
                          iconColor: Colors.greenAccent,
                          label: 'Volume Total',
                          value: '${totalVolume.toStringAsFixed(0)} kg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Glowing Button to return
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'VOLTAR AO INÍCIO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinishStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showMusicBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _WorkoutMusicPanel(),
    );
  }

  void _showAddReferenceBottomSheet(BuildContext context, Exercise ex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddReferencePanel(
        exercise: ex,
        onSaved: (newLink) async {
          final updated = ex.copyWith(link: drift.Value(newLink));
          await ref.read(exerciseDaoProvider).updateExercise(updated);
          setState(() {
            _exercises[_currentIndex] = updated;
          });
          if (mounted) Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Referência salva com sucesso!')),
          );
        },
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.onSurface)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.onBackground)),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(restTimerProvider);
    final _resting = timerState.isActive;
    final _restLeft = timerState.remainingSeconds;
    final _restTotal = timerState.totalSeconds;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.dayName)),
        body: const Center(
          child: Text('Nenhum exercício configurado para este dia.'),
        ),
      );
    }

    final ex = _current;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sair do treino?'),
            content: const Text('O treino será marcado como em andamento.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continuar')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sair')),
            ],
          ),
        );
        if (ok == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.dayName),
          actions: [
            // Cronômetro da sessão
            Center(
              child: Text(
                WeekUtils.formatDuration(_sessionSecs),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.music_note_rounded, color: AppColors.primaryLight),
              tooltip: 'Música',
              onPressed: () => _showMusicBottomSheet(context),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: _confirmarFinalizarTreino,
              icon: const Icon(Icons.check_rounded,
                  color: AppColors.primaryLight, size: 18),
              label: const Text(
                'Finalizar',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Barra de progresso
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _exercises.length,
              minHeight: 3,
            ),

            // Banner de descanso
            if (_resting)
              _RestBanner(
                left: _restLeft,
                total: _restTotal,
                onSkip: _skipRest,
              ),

            // Conteúdo scrollável
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  // ── Contador + grupo ───────────────────────────
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: AppColors.onSurface),
                        onPressed: _exercises.length > 1
                            ? () async {
                                setState(() {
                                  _currentIndex =
                                      (_currentIndex - 1 + _exercises.length) %
                                          _exercises.length;
                                });
                                await _loadExerciseContext();
                              }
                            : null,
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<int>(
                        tooltip: 'Selecionar exercício',
                        color: AppColors.card,
                        onSelected: (index) async {
                          setState(() {
                            _currentIndex = index;
                          });
                          await _loadExerciseContext();
                        },
                        itemBuilder: (context) {
                          return _exercises.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final e = entry.value;
                            final isCurrent = idx == _currentIndex;
                            return PopupMenuItem<int>(
                              value: idx,
                              child: Row(
                                children: [
                                  if (isCurrent)
                                    const Icon(Icons.play_arrow_rounded,
                                        color: AppColors.primary, size: 16)
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.nome,
                                      style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isCurrent
                                            ? AppColors.primaryLight
                                            : AppColors.onBackground,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentIndex + 1} / ${_exercises.length}',
                              style: const TextStyle(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down_rounded,
                                color: AppColors.onSurface, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.onSurface),
                        onPressed: _exercises.length > 1
                            ? () async {
                                setState(() {
                                  _currentIndex =
                                      (_currentIndex + 1) % _exercises.length;
                                });
                                await _loadExerciseContext();
                              }
                            : null,
                      ),
                      const Spacer(),
                      _Chip(ex.grupoMuscular),
                      if (ex.equipamento != 'Livre') ...[
                        const SizedBox(width: 6),
                        _Chip(ex.equipamento),
                      ],
                      if (ex.volume != null && ex.volume!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Chip(ex.volume!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Nome do exercício ──────────────────────────
                  Text(
                    ex.nome,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                  ),

                  // ── Badges ────────────────────────────────────
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (ex.isUnilateral)
                        const _BadgeTag(
                          label: 'Unilateral',
                          icon: Icons.swap_horiz_rounded,
                        ),
                      _BadgeTag(
                        label: 'Descanso ${ex.tempoDescansoSegundos}s',
                        icon: Icons.timer_rounded,
                        color: AppColors.info,
                      ),
                      if (ex.link != null && ex.link!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _openLink(ex.link!),
                          onLongPress: () => _showAddReferenceBottomSheet(context, ex),
                          child: const _BadgeTag(
                            label: 'Ver referência',
                            icon: Icons.play_circle_rounded,
                            color: AppColors.warning,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showAddReferenceBottomSheet(context, ex),
                          child: const _BadgeTag(
                            label: 'Adicionar referência',
                            icon: Icons.add_circle_outline_rounded,
                            color: AppColors.onSurface,
                          ),
                        ),
                    ],
                  ),

                  // ── Observações / Biomecânica do Exercício ──
                  if (ex.observacoes != null && ex.observacoes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology_alt_rounded, size: 16, color: AppColors.primaryLight),
                              SizedBox(width: 6),
                              Text(
                                'Detalhes & Biomecânica',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ex.observacoes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onBackground,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Desempenho anterior ────────────────────────
                  if (_prevLogs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PreviousPerformance(logs: _prevLogs, exercise: ex),
                  ],

                  // ── Séries já salvas nesta sessão ──────────────
                  if (_setsLogged.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SetsList(sets: _setsLogged, exercise: ex),
                  ],

                  // ── Inputs ────────────────────────────────────
                  const SizedBox(height: 20),
                  _InputRow(
                    serie: _currentSerie,
                    pesoCtrl: _pesoCtrl,
                    repsCtrl: _repsCtrl,
                    obsCtrl: _obsCtrl,
                  ),

                  // ── Modo de Execução ──
                  const SizedBox(height: 16),
                  const Text(
                    'MODO DE EXECUÇÃO',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('Bilateral'),
                          icon: Icon(Icons.people_rounded)),
                      ButtonSegment(
                          value: true,
                          label: Text('Unilateral'),
                          icon: Icon(Icons.person_rounded)),
                    ],
                    selected: {_executandoUnilateral},
                    onSelectionChanged: (v) {
                      setState(() {
                        _executandoUnilateral = v.first;
                        if (!_executandoUnilateral) {
                          _lado = 'ambos'; // Reseta para ambos
                        }
                      });
                    },
                  ),

                  // ── Lado (apenas se unilateral) ───────────────────
                  if (_executandoUnilateral) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'LADO EM EXECUÇÃO',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ambos', label: Text('Ambos')),
                        ButtonSegment(value: 'esquerdo', label: Text('Esq.')),
                        ButtonSegment(value: 'direito', label: Text('Dir.')),
                      ],
                      selected: {_lado},
                      onSelectionChanged: (v) =>
                          setState(() => _lado = v.first),
                    ),
                  ],

                  // ── Equipamento Utilizado (Sobrescrever Recomendação) ──
                  const SizedBox(height: 16),
                  const Text(
                    'EQUIPAMENTO UTILIZADO',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _equipamentoSelecionado,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: AppColors.card,
                    items: equipmentOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _equipamentoSelecionado = val;
                      });
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // ── Botões de ação ─────────────────────────────────
            _ActionBar(
              isLast: _isLast,
              resting: _resting,
              hasSets: _setsLogged.isNotEmpty,
              onSkip: _pularExercicio,
              onSalvarSerie: _salvarSerie,
              onProximo: _proximoExercicio,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falha silenciosa ou log
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RestBanner extends StatelessWidget {
  final int left;
  final int total;
  final VoidCallback onSkip;
  const _RestBanner(
      {required this.left, required this.total, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? left / total : 0.0;
    final m = (left ~/ 60).toString().padLeft(2, '0');
    final s = (left % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text(
                  '$m:$s',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DESCANSO',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Próxima série quando pronto',
                style: TextStyle(color: AppColors.onSurface, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: const Text('Pular'),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.onSurface, size: 20),
            onPressed: onSkip,
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }
}

class _PreviousPerformance extends StatelessWidget {
  final List<ExerciseLog> logs;
  final Exercise exercise;
  const _PreviousPerformance({required this.logs, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÚLTIMO TREINO',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: logs.map((l) {
              final ladoStr = (l.lado != 'ambos') ? ' (${l.lado})' : '';
              final eqStr = (l.equipamento != null &&
                      l.equipamento != exercise.equipamento)
                  ? ' [${l.equipamento}]'
                  : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'S${l.serie}: ${l.peso}kg × ${l.repeticoes}$ladoStr$eqStr',
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SetsList extends StatelessWidget {
  final List<_SetEntry> sets;
  final Exercise exercise;
  const _SetsList({required this.sets, required this.exercise});

  @override
  Widget build(BuildContext context) {
    // Group sets by serie number, preserving insertion order
    final Map<int, List<_SetEntry>> grouped = {};
    for (final s in sets) {
      grouped.putIfAbsent(s.serie, () => []).add(s);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(red: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SÉRIES SALVAS',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: grouped.values.map((group) {
              final formattedText = _formatSeriesGroup(group);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formattedText,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatSeriesGroup(List<_SetEntry> entries) {
    if (entries.isEmpty) return '';
    final s = entries.first;
    final serieLabel = 'S${s.serie}:';
    
    // Equipment and observations usually match, let's grab them from first or combine
    final eqStr = (s.equipamento != null && s.equipamento != exercise.equipamento)
        ? ' [${s.equipamento}]'
        : '';
    final obsStr = (s.observacoes != null && s.observacoes!.isNotEmpty)
        ? ' (${s.observacoes})'
        : '';

    if (entries.length == 1) {
      final ladoStr = (s.lado != 'ambos') 
          ? ' (${s.lado == 'esquerdo' ? 'E' : s.lado == 'direito' ? 'D' : s.lado})' 
          : '';
      return '$serieLabel ${s.peso}kg × ${s.reps}$ladoStr$eqStr$obsStr';
    }

    // Check if all entries in this series have the same weight
    final allSameWeight = entries.every((e) => e.peso == s.peso);
    if (allSameWeight) {
      final allSameReps = entries.every((e) => e.reps == s.reps);
      if (allSameReps) {
        // S1: 10kg × 10 (E+D)
        return '$serieLabel ${s.peso}kg × ${s.reps} (E+D)$eqStr$obsStr';
      } else {
        // S1: 10kg × 10(E) / 8(D)
        final repsMap = entries.map((e) {
          final sideLetter = e.lado == 'esquerdo' ? 'E' : e.lado == 'direito' ? 'D' : e.lado;
          return '${e.reps}($sideLetter)';
        }).join(' / ');
        return '$serieLabel ${s.peso}kg × $repsMap$eqStr$obsStr';
      }
    } else {
      // S1: 10kg × 10(E) / 12kg × 8(D)
      final parts = entries.map((e) {
        final sideLetter = e.lado == 'esquerdo' ? 'E' : e.lado == 'direito' ? 'D' : e.lado;
        return '${e.peso}kg × ${e.reps}($sideLetter)';
      }).join(' / ');
      return '$serieLabel $parts$eqStr$obsStr';
    }
  }
}

class _InputRow extends StatelessWidget {
  final int serie;
  final TextEditingController pesoCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController obsCtrl;
  const _InputRow({
    required this.serie,
    required this.pesoCtrl,
    required this.repsCtrl,
    required this.obsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SÉRIE $serie',
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                ctrl: pesoCtrl,
                label: 'Peso (kg)',
                decimal: true,
                step: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                ctrl: repsCtrl,
                label: 'Repetições',
                step: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: obsCtrl,
          decoration: const InputDecoration(
            labelText: 'Observações (ex: banco 80°, drop set)',
            labelStyle: TextStyle(fontSize: 12),
            prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool disabled;

  const _CircleButton({
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surface.withOpacity(0.6)
                : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: disabled
                  ? AppColors.onSurface.withOpacity(0.5)
                  : AppColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final bool decimal;
  final double step;

  const _NumberField({
    required this.ctrl,
    required this.label,
    this.decimal = false,
    required this.step,
    Key? key,
  }) : super(key: key);

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  double _value = 0.0;

  @override
  void initState() {
    super.initState();
    _parseValue();
    widget.ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() => _parseValue());
  }

  void _parseValue() {
    final text = widget.ctrl.text.replaceAll(',', '.');
    _value = double.tryParse(text) ?? 0.0;
    if (_value < 0) _value = 0;
  }

  void _adjustValue(double delta) {
    final newVal = (_value + delta).clamp(0.0, double.infinity);
    double val = newVal;
    if (widget.decimal) {
      if (val % 1 == 0) {
        widget.ctrl.text = val.toInt().toString();
      } else {
        if ((val * 2) % 1 == 0) {
          widget.ctrl.text = val.toStringAsFixed(1);
        } else {
          widget.ctrl.text = val.toStringAsFixed(2);
        }
      }
    } else {
      widget.ctrl.text = val.toInt().toString();
    }
    setState(() => _parseValue());
  }

  @override
  Widget build(BuildContext context) {
    final minusDisabled = _value <= 0.0;
    return Row(
      children: [
        Tooltip(
          message: 'Diminuir',
          child: _CircleButton(
            icon: Icons.remove_rounded,
            onPressed: minusDisabled ? null : () => _adjustValue(-widget.step),
            size: 44,
            disabled: minusDisabled,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: widget.ctrl,
            textAlign: TextAlign.center,
            keyboardType:
                TextInputType.numberWithOptions(decimal: widget.decimal),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: const TextStyle(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Aumentar',
          child: _CircleButton(
            icon: Icons.add_rounded,
            onPressed: () => _adjustValue(widget.step),
            size: 44,
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isLast;
  final bool resting;
  final bool hasSets;
  final VoidCallback onSkip;
  final VoidCallback onSalvarSerie;
  final VoidCallback onProximo;

  const _ActionBar({
    required this.isLast,
    required this.resting,
    required this.hasSets,
    required this.onSkip,
    required this.onSalvarSerie,
    required this.onProximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Pular exercício
          OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Pular'),
          ),
          const SizedBox(width: 8),

          // Salvar série
          Expanded(
            child: ElevatedButton.icon(
              onPressed: resting ? null : onSalvarSerie,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Salvar Série'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Próximo / Finalizar
          Expanded(
            child: ElevatedButton(
              onPressed: onProximo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLast ? 'Finalizar' : 'Próximo'),
                  const SizedBox(width: 4),
                  Icon(
                    isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.onSurface, fontSize: 11),
      ),
    );
  }
}

class _BadgeTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _BadgeTag({
    required this.label,
    required this.icon,
    this.color = AppColors.primaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _WorkoutMusicPanel extends ConsumerStatefulWidget {
  const _WorkoutMusicPanel();

  @override
  ConsumerState<_WorkoutMusicPanel> createState() => _WorkoutMusicPanelState();
}

class _WorkoutMusicPanelState extends ConsumerState<_WorkoutMusicPanel> {
  String? _customAppName;
  String? _customAppPackage;

  @override
  void initState() {
    super.initState();
    _loadCustomApp();
  }

  Future<void> _loadCustomApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customAppName = prefs.getString('custom_music_app_name');
      _customAppPackage = prefs.getString('custom_music_app_package');
    });
  }

  /*
  Future<void> _saveCustomApp(String name, String package) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_music_app_name', name);
    await prefs.setString('custom_music_app_package', package);
    setState(() {
      _customAppName = name;
      _customAppPackage = package;
    });
  }
  */

  Future<void> _clearCustomApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_music_app_name');
    await prefs.remove('custom_music_app_package');
    setState(() {
      _customAppName = null;
      _customAppPackage = null;
    });
  }

  /*
  void _showAddCustomAppDialog() {
    final nameCtrl = TextEditingController();
    final packageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Adicionar App de Música'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite o nome do aplicativo e o ID do pacote Android (Package Name) para abrir diretamente.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Aplicativo',
                hintText: 'Ex: Poweramp, VLC, Musicolet',
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
              ),
              style: const TextStyle(color: AppColors.onBackground),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: packageCtrl,
              decoration: const InputDecoration(
                labelText: 'ID do Pacote Android (Package Name)',
                hintText: 'Ex: com.maxmpz.audioplayer',
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
              ),
              style: const TextStyle(color: AppColors.onBackground),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final package = packageCtrl.text.trim();
              if (name.isNotEmpty && package.isNotEmpty) {
                _saveCustomApp(name, package);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(workoutMusicProvider);
    final musicNotifier = ref.read(workoutMusicProvider.notifier);

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.music_note_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text(
                      'Rádio de Treino',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: AppColors.primary.withOpacity(0.1),
                      child: musicState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                              ),
                            )
                          : Icon(
                              musicState.isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
                              color: AppColors.primaryLight,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musicChannels[musicState.currentChannelIndex].name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          musicChannels[musicState.currentChannelIndex].genre,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      musicState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.onBackground,
                      size: 28,
                    ),
                    onPressed: () => musicNotifier.togglePlay(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.stop_rounded,
                      color: AppColors.onSurface,
                      size: 24,
                    ),
                    onPressed: () => musicNotifier.stop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Estações de Foco / Energia',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(musicChannels.length, (index) {
                final channel = musicChannels[index];
                final isSelected = musicState.currentChannelIndex == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == musicChannels.length - 1 ? 0 : 4,
                    ),
                    child: InkWell(
                      onTap: () => musicNotifier.playChannel(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              channel.name.split(' ').first,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primaryLight : AppColors.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              channel.genre.split(' / ').first,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              'Abrir em aplicativos externos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MusicAppLinkButton(
                    name: 'Spotify',
                    assetPath: 'assets/images/spotify.png',
                    packageName: 'com.spotify.music',
                    url: 'spotify:',
                    fallbackUrl: 'https://open.spotify.com',
                  ),
                  const SizedBox(width: 8),
                  _MusicAppLinkButton(
                    name: 'YT Music',
                    assetPath: 'assets/images/ytmusic.png',
                    packageName: 'com.google.android.apps.youtube.music',
                    url: 'https://music.youtube.com',
                    fallbackUrl: 'https://music.youtube.com',
                  ),
                  const SizedBox(width: 8),
                  _MusicAppLinkButton(
                    name: 'Deezer',
                    assetPath: 'assets/images/deezer.png',
                    packageName: 'deezer.android.app',
                    url: 'deezer://',
                    fallbackUrl: 'https://www.deezer.com',
                  ),
                  const SizedBox(width: 8),
                  _MusicAppLinkButton(
                    name: 'Samsung',
                    assetPath: 'assets/images/samsung_music.png',
                    packageName: 'com.sec.android.app.music',
                    url: 'android-music-player://',
                    fallbackUrl: 'https://play.google.com/store/apps/details?id=com.sec.android.app.music',
                  ),
                  const SizedBox(width: 8),
                  _MusicAppLinkButton(
                    name: 'Mi Music',
                    assetPath: 'assets/images/mi_music.png',
                    packageName: 'com.miui.player',
                    url: 'miui-music://',
                    fallbackUrl: 'https://play.google.com/store/apps/details?id=com.miui.player',
                  ),
                  if (_customAppName != null && _customAppPackage != null) ...[
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        _MusicAppLinkButton(
                          name: _customAppName!,
                          assetPath: 'assets/images/generic_player.png',
                          packageName: _customAppPackage,
                          url: 'intent:#Intent;package=$_customAppPackage;end',
                          fallbackUrl: 'https://play.google.com/store/apps/details?id=$_customAppPackage',
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _clearCustomApp,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  /*
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddCustomAppDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 95,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.divider,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: AppColors.onSurface, size: 20),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '+ Outro',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicAppLinkButton extends StatelessWidget {
  final String name;
  final String assetPath;
  final String? packageName;
  final String url;
  final String fallbackUrl;

  const _MusicAppLinkButton({
    required this.name,
    required this.assetPath,
    this.packageName,
    required this.url,
    required this.fallbackUrl,
  });

  static const _channel = MethodChannel('com.example.gym/app_launcher');

  Future<void> _launch() async {
    // 1. Tenta abrir via pacote Android se disponível
    if (packageName != null) {
      try {
        final bool launched = await _channel.invokeMethod('launchApp', {
          'packageName': packageName,
        });
        if (launched) return;
      } catch (_) {}
    }

    // 2. Tenta abrir via esquema customizado
    try {
      final appUri = Uri.parse(url);
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (launched) return;
    } catch (_) {}

    // 3. Fallback final para o navegador
    try {
      final webUri = Uri.parse(fallbackUrl);
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launch,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                assetPath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReferencePanel extends StatefulWidget {
  final Exercise exercise;
  final Function(String) onSaved;

  const _AddReferencePanel({
    required this.exercise,
    required this.onSaved,
  });

  @override
  State<_AddReferencePanel> createState() => _AddReferencePanelState();
}

class _AddReferencePanelState extends State<_AddReferencePanel> with WidgetsBindingObserver {
  final _linkController = TextEditingController();
  String? _detectedClipboardLink;
  bool _checkingClipboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (_checkingClipboard) return;
    if (!mounted) return;
    setState(() => _checkingClipboard = true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null &&
          (text.contains('youtube.com') ||
              text.contains('youtu.be') ||
              text.contains('tiktok.com'))) {
        if (mounted) {
          setState(() {
            _detectedClipboardLink = text.trim();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _detectedClipboardLink = null;
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _checkingClipboard = false);
    }
  }

  void _searchYouTube() async {
    final query = 'como fazer ${widget.exercise.nome}';
    final url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
    final uri = Uri.parse(url);
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o YouTube')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o YouTube: $e')),
        );
      }
    }
  }

  void _searchTikTok() async {
    final query = 'como fazer ${widget.exercise.nome}';
    final appUrl = 'tiktok://search?keyword=${Uri.encodeComponent(query)}';
    final webUrl = 'https://www.tiktok.com/search?q=${Uri.encodeComponent(query)}';

    // Tenta abrir direto no app do TikTok
    try {
      final success = await launchUrl(Uri.parse(appUrl), mode: LaunchMode.externalApplication);
      if (success) return;
    } catch (_) {
      // Ignora erro e tenta o fallback web
    }

    // Fallback: abre no browser (ou no app caso o Android resolva o link HTTPS)
    try {
      final success = await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o TikTok')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o TikTok: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Execução: ${widget.exercise.nome}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Busque a execução no YouTube ou TikTok. Ao copiar o link do vídeo e retornar para o app, você poderá colar e salvar o link abaixo como referência definitiva para este exercício.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _searchYouTube,
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                  label: const Text('YouTube'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white10, width: 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _searchTikTok,
                  icon: const Icon(Icons.music_note, color: Colors.white, size: 18),
                  label: const Text('TikTok'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF010101),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white10, width: 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_detectedClipboardLink != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.content_paste_go_rounded, color: AppColors.primaryLight, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Link detectado na Área de Transferência:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _detectedClipboardLink!,
                    style: const TextStyle(fontSize: 12, color: AppColors.onBackground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSaved(_detectedClipboardLink!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Usar Link Copiado & Salvar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Link de referência manual',
              hintText: 'https://www.youtube.com/watch?...',
              labelStyle: const TextStyle(color: AppColors.onSurface),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded, color: AppColors.primaryLight),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _linkController.text = data!.text!.trim();
                  }
                },
              ),
            ),
            style: const TextStyle(color: AppColors.onBackground),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final link = _linkController.text.trim();
              if (link.isNotEmpty) {
                widget.onSaved(link);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Salvar Referência'),
          ),
        ],
      ),
    );
  }
}
