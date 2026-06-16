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
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/constants/equipment_options.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/rest_timer_provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';
import '../../core/utils/decimal_input_formatter.dart';
import 'widgets/plate_calculator_dialog.dart';
import 'widgets/workout_music_panel.dart';
import '../../core/services/health_connect_service.dart';
//import '../setup/widgets/setup_page.dart';

// Registro local de uma série (exibição imediata, sem roundtrip)
class _SetEntry {
  final int? id;
  final int serie;
  final double peso;
  final int reps;
  final String lado;
  final String? equipamento;
  final String? observacoes;
  _SetEntry({
    this.id,
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
  double _max1RM = 0.0; // recorde máximo 1RM histórico do exercício

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
    NotificationService.requestPermission();
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

    // Busca desempenho do último treino para pré-preencher os campos (excluindo a sessão atual)
    final prev = await ref.read(logDaoProvider).getLastLogsForExercise(
          ex.id,
          excludeSessionId: widget.sessionId,
        );

    // Busca recorde máximo 1RM histórico
    final prevMax1RM = await ref.read(logDaoProvider).getMax1RMForExercise(ex.id);

    // Busca logs já realizados na sessão atual para este exercício
    final currentLogs =
        await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
    final exerciseSessionLogs =
        currentLogs.where((l) => l.exerciseId == ex.id).toList();

    final isBodyWeight = ex.equipamento.trim().toLowerCase() == 'peso corporal';

    // Busca o peso do perfil diretamente do banco de dados (evita race conditions com providers reativos em carregamento)
    final profile = await ref.read(profileDaoProvider).getProfile();
    final userWeight = profile?.pesoAtual ?? 70.0;

    setState(() {
      _max1RM = prevMax1RM;
      _prevLogs = prev;
      final numUniqueSeries = exerciseSessionLogs.map((l) => l.serie).toSet().length;
      _currentSerie = numUniqueSeries + 1;
      _setsLogged.clear();
      _setsLogged.addAll(exerciseSessionLogs.map((l) => _SetEntry(
            id: l.id,
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
        final lastPeso = exerciseSessionLogs.last.peso;
        _pesoCtrl.text = lastPeso % 1 == 0
            ? lastPeso.toInt().toString()
            : lastPeso.toString();
        _repsCtrl.text = exerciseSessionLogs.last.repeticoes.toString();
      } else if (prev.isNotEmpty) {
        final totalPeso = prev.map((l) => l.peso).fold<double>(0.0, (a, b) => a + b);
        final totalReps = prev.map((l) => l.repeticoes).fold<int>(0, (a, b) => a + b);
        double avgPeso = ((totalPeso / prev.length) / 2).round() * 2.0;
        final avgReps = (totalReps / prev.length).round();

        if (isBodyWeight && avgPeso <= 0.0) {
          avgPeso = _obterPesoCorporalEstimado(
            pesoUsuario: userWeight,
            nomeExercicio: ex.nome,
            grupoMuscular: ex.grupoMuscular,
          );
        }

        final pesoStr = avgPeso % 1 == 0 
            ? avgPeso.toInt().toString() 
            : avgPeso.toStringAsFixed(1);

        _pesoCtrl.text = pesoStr;
        _repsCtrl.text = avgReps.toString();
      } else {
        if (isBodyWeight) {
          final estWeight = _obterPesoCorporalEstimado(
            pesoUsuario: userWeight,
            nomeExercicio: ex.nome,
            grupoMuscular: ex.grupoMuscular,
          );
          _pesoCtrl.text = estWeight % 1 == 0
              ? estWeight.toInt().toString()
              : estWeight.toStringAsFixed(1);
        } else {
          _pesoCtrl.text = '0';
        }
        _repsCtrl.text = '10';
      }
    });

    if (exerciseSessionLogs.isEmpty && isBodyWeight) {
      final estWeight = _obterPesoCorporalEstimado(
        pesoUsuario: userWeight,
        nomeExercicio: ex.nome,
        grupoMuscular: ex.grupoMuscular,
      );
      
      final double pct;
      final nome = ex.nome.toLowerCase();
      final grupo = ex.grupoMuscular.toLowerCase();
      if (nome.contains('flexão') || nome.contains('pushup') || nome.contains('push-up')) {
        pct = 65;
      } else if (grupo == 'core' || nome.contains('abdominal') || nome.contains('prancha') || nome.contains('crunch')) {
        pct = 35;
      } else if (nome.contains('agachamento') || nome.contains('squat')) {
        pct = 60;
      } else {
        pct = 100;
      }

      final estWeightStr = estWeight % 1 == 0
          ? estWeight.toInt().toString()
          : estWeight.toStringAsFixed(1);

      final userWeightStr = userWeight % 1 == 0
          ? userWeight.toInt().toString()
          : userWeight.toStringAsFixed(1);

      // Usando delay de 500ms para garantir que a transição de tela terminou e o ScaffoldMessenger encontre o Scaffold montado
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exercício de Peso Corporal: peso inicial estimado em ${pct.toInt()}% do seu peso ($userWeightStr kg) = $estWeightStr kg.',
                style: const TextStyle(fontSize: 13),
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      });
    }
  }

  double _obterPesoCorporalEstimado({
    required double pesoUsuario,
    required String nomeExercicio,
    required String grupoMuscular,
  }) {
    final nome = nomeExercicio.toLowerCase();
    final grupo = grupoMuscular.toLowerCase();

    // 1. Flexão de braço (Push-ups)
    if (nome.contains('flexão') || nome.contains('pushup') || nome.contains('push-up')) {
      if (!nome.contains('quadril') && !nome.contains('plantar') && !nome.contains('perna') && !nome.contains('joelho')) {
        return pesoUsuario * 0.65;
      }
    }

    // 2. Abdominais / Core (Crunches, prancha)
    if (grupo == 'core' || nome.contains('abdominal') || nome.contains('prancha') || nome.contains('crunch')) {
      return pesoUsuario * 0.35;
    }

    // 3. Agachamento livre / corporal (Squats)
    if (nome.contains('agachamento') || nome.contains('squat')) {
      return pesoUsuario * 0.60;
    }

    // 4. Barra fixa, paralelas, etc. (Pull-ups, chin-ups, dips)
    return pesoUsuario;
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

  void _showPrCelebration(double peso, int reps, double new1RM, double prevMax1RM) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber[900],
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.yellowAccent, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECORDE PESSOAL! 🏆',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Você superou seu recorde anterior neste exercício!',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Novo 1RM Estimado: ${new1RM.toStringAsFixed(1)} kg (era ${prevMax1RM.toStringAsFixed(1)} kg)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlateCalculator() {
    showDialog(
      context: context,
      builder: (ctx) {
        return PlateCalculatorDialog(
          initialWeight: double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 60.0,
          onApplyWeight: (newWeight) {
            setState(() {
              _pesoCtrl.text = newWeight % 1 == 0
                  ? newWeight.toInt().toString()
                  : newWeight.toStringAsFixed(1);
            });
          },
        );
      },
    );
  }

  Future<void> _salvarSerie() async {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;

    if (reps <= 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As repetições devem ser maiores que zero.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (peso <= 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A carga deve ser maior que zero.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final obs = _obsCtrl.text.trim();
    final logDao = ref.read(logDaoProvider);
    final now = DateTime.now().toIso8601String();
    final Value<String?> valueObs = obs.isNotEmpty ? Value<String?>(obs) : const Value<String?>.absent();

    final double new1RM = reps == 1 ? peso : peso * (1 + reps / 30.0);
    final double prevMax1RM = _max1RM;
    final bool isPR = prevMax1RM > 0 && new1RM > prevMax1RM;

    final List<int> insertedIds = [];
    try {
      if (_executandoUnilateral && _lado == 'ambos') {
        // Grava dois logs: esquerdo e direito
        for (final l in ['esquerdo', 'direito']) {
          final id = await logDao.insertLog(ExerciseLogsCompanion.insert(
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
          insertedIds.add(id);
        }
      } else {
        final id = await logDao.insertLog(ExerciseLogsCompanion.insert(
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
        insertedIds.add(id);
      }
    } catch (e, stack) {
      debugPrint('Erro ao inserir log no banco: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no banco: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return;
    }

    _obsCtrl.clear();

    if (isPR) {
      AudioService().prCelebration();
      _showPrCelebration(peso, reps, new1RM, prevMax1RM);
    } else {
      AudioService().beep();
    }

    setState(() {
      if (isPR || prevMax1RM == 0.0) {
        if (new1RM > _max1RM) {
          _max1RM = new1RM;
        }
      }
      if (_executandoUnilateral && _lado == 'ambos') {
        _setsLogged.add(_SetEntry(
          id: insertedIds[0],
          serie: _currentSerie,
          peso: peso,
          reps: reps,
          lado: 'esquerdo',
          equipamento: _equipamentoSelecionado,
          observacoes: obs.isNotEmpty ? obs : null,
        ));
        _setsLogged.add(_SetEntry(
          id: insertedIds[1],
          serie: _currentSerie,
          peso: peso,
          reps: reps,
          lado: 'direito',
          equipamento: _equipamentoSelecionado,
          observacoes: obs.isNotEmpty ? obs : null,
        ));
      } else {
        _setsLogged.add(_SetEntry(
          id: insertedIds[0],
          serie: _currentSerie,
          peso: peso,
          reps: reps,
          lado: _lado,
          equipamento: _equipamentoSelecionado,
          observacoes: obs.isNotEmpty ? obs : null,
        ));
      }
      _currentSerie++;
    });

    _startRestTimer(_current.tempoDescansoSegundos);

    final expectedSets = _obterSeriesEsperadas(_current.volume);
    if (expectedSets != null && _setsLogged.length >= expectedSets) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Você completou as $expectedSets séries recomendadas!',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _proximoExercicio();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primaryLight,
                  ),
                  child: const Text(
                    'IR PARA O PRÓXIMO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: context.onSurface,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ],
            ),
            duration: const Duration(seconds: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }
  }

  Future<void> _deletarSerie(int serieNum) async {
    final logDao = ref.read(logDaoProvider);
    
    // Encontra todos os logs desta série para o exercício atual na sessão atual
    final entriesToDelete = _setsLogged.where((e) => e.serie == serieNum).toList();
    
    for (final entry in entriesToDelete) {
      if (entry.id != null) {
        await logDao.deleteLog(entry.id!);
      }
    }
    
    // Re-sequenciar as séries seguintes no banco
    final dbLogs = await logDao.getLogsForSession(widget.sessionId);
    final exerciseLogs = dbLogs.where((l) => l.exerciseId == _current.id).toList();
    for (final log in exerciseLogs) {
      if (log.serie > serieNum) {
        await logDao.updateLogSerie(log.id, log.serie - 1);
      }
    }
    
    await _loadExerciseContext();
  }

  Future<void> _showEditDeleteSeriesDialog(int serieNum) async {
    final group = _setsLogged.where((e) => e.serie == serieNum).toList();
    if (group.isEmpty) return;

    // Crie os controllers
    final controllers = group.map((entry) {
      final pesoStr = entry.peso % 1 == 0 ? entry.peso.toInt().toString() : entry.peso.toString();
      return _EditControllers(
        entry: entry,
        pesoCtrl: TextEditingController(text: pesoStr),
        repsCtrl: TextEditingController(text: entry.reps.toString()),
        obsCtrl: TextEditingController(text: entry.observacoes ?? ''),
      );
    }).toList();

    final isDark = context.isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 24,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Editar Série $serieNum',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ...controllers.map((c) {
                  final hasLado = c.entry.lado != 'ambos';
                  final isEsquerdo = c.entry.lado == 'esquerdo';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface.withValues(alpha: 0.5)
                          : AppColors.lightBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasLado) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isEsquerdo ? AppColors.info : AppColors.success)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEsquerdo ? Icons.keyboard_arrow_left_rounded : Icons.keyboard_arrow_right_rounded,
                                      size: 14,
                                      color: isEsquerdo ? AppColors.info : AppColors.success,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      isEsquerdo ? 'ESQUERDO' : 'DIREITO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isEsquerdo ? AppColors.info : AppColors.success,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        _NumberField(
                          ctrl: c.pesoCtrl,
                          label: 'Peso (kg)',
                          decimal: true,
                          step: 0.5,
                        ),
                        const SizedBox(height: 12),
                        _NumberField(
                          ctrl: c.repsCtrl,
                          label: 'Repetições',
                          step: 1.0,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: c.obsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            labelStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    // Confirmação para excluir
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (cConfirm) => AlertDialog(
                        backgroundColor: context.cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                            SizedBox(width: 8),
                            Text('Excluir Série?'),
                          ],
                        ),
                        content: const Text('Tem certeza que deseja excluir esta série de forma permanente?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(cConfirm, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(cConfirm, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Excluir'),
                            
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && ctx.mounted) {
                      Navigator.pop(ctx); // fecha o diálogo de edição
                      await _deletarSerie(serieNum);
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text(
                    'Excluir',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        // Validação e Salvamento
                        final logDao = ref.read(logDaoProvider);
                        for (final c in controllers) {
                          final peso = double.tryParse(c.pesoCtrl.text.replaceAll(',', '.')) ?? 0.0;
                          final reps = int.tryParse(c.repsCtrl.text) ?? 0;
                          final obs = c.obsCtrl.text.trim();

                          if (reps <= 0 || peso <= 0) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Carga e repetições devem ser maiores que zero.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }

                          if (c.entry.id != null) {
                            await logDao.updateLog(
                              c.entry.id!,
                              peso,
                              reps,
                              obs.isNotEmpty ? obs : null,
                            );
                          }
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        await _loadExerciseContext();
                      },
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) {
      // Liberar controllers
      for (final c in controllers) {
        c.dispose();
      }
    });
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
          backgroundColor: context.cardColor,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Exercícios Pendentes'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você ainda não registrou nenhuma série para os seguintes exercícios:',
                  style: TextStyle(color: context.onSurface),
                ),
                const SizedBox(height: 16),
                Column(
                  children: uncompleted.map((entry) {
                    final ex = entry.value;
                    final muscle = ex.grupoMuscular;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.divider,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            Navigator.pop(ctx);
                            setState(() {
                              _currentIndex = entry.key;
                            });
                            await _loadExerciseContext();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.nome,
                                        style: TextStyle(
                                          color: context.onBackground,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (muscle.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: context.divider,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            muscle.toUpperCase(),
                                            style: TextStyle(
                                              color: context.onSurface,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: context.onSurface.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deseja finalizar o treino mesmo assim ou voltar para realizá-los?',
                  style: TextStyle(color: context.onSurface),
                ),
              ],
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _finalizarTreino();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: const BorderSide(color: AppColors.primaryLight),
                  ),
                  child: const Text('Finalizar mesmo assim'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
              ],
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

    // Sincronizar treino finalizado com o Health Connect
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(seconds: _sessionSecs));
      final calories = (_sessionSecs / 60.0) * 5.0; // estimativa de 5 kcal/min
      await HealthConnectService.instance.syncWorkout(
        title: widget.dayName,
        start: start,
        end: now,
        estimatedCaloriesBurned: calories,
      );
    } catch (e) {
      debugPrint('Erro ao sincronizar treino com Health Connect: $e');
    }

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
    final isDark = context.isDark;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.85),
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
                      context.cardColor.withValues(alpha: 0.95),
                      context.cardColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
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
                            color: Colors.orange.withValues(alpha: 0.4),
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
                    Text(
                      'TREINO CONCLUÍDO!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mais um treino pra conta, Mete Marcha! 🔥',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: context.divider, height: 1),
                    const SizedBox(height: 20),

                    // Stats Rows (Row 1 + Row 2 instead of GridView)
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.timer_rounded,
                            iconColor: Colors.blueAccent,
                            label: 'Duração',
                            value: WeekUtils.formatDuration(_sessionSecs),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.fitness_center_rounded,
                            iconColor: AppColors.primaryLight,
                            label: 'Exercícios',
                            value: '$uniqueExercises',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.view_headline_rounded,
                            iconColor: Colors.purpleAccent,
                            label: 'Séries',
                            value: '$totalSets',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.flash_on_rounded,
                            iconColor: Colors.greenAccent,
                            label: 'Volume Total',
                            value: '${totalVolume.toStringAsFixed(0)} kg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Glowing Button to Share
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            final dayNameClean = widget.dayName.toLowerCase().contains('treino')
                                ? widget.dayName
                                : 'Treino de ${widget.dayName}';
                            final durationMin = (_sessionSecs / 60).round();
                            final formattedVolume = _formatVolume(totalVolume);
                            final shareText =
                                "Meteu Marcha! 🔥 $dayNameClean concluído: $uniqueExercises ${uniqueExercises == 1 ? 'exercício' : 'exercícios'} | $durationMin min | ${formattedVolume}kg totais. #MeteMarcha";
                            SharePlus.instance.share(ShareParams(text: shareText));
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
                              Icon(Icons.share_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'COMPARTILHAR TREINO',
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
                    const SizedBox(height: 12),
                    
                    // Voltar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, size: 18, color: context.onSurface),
                            const SizedBox(width: 8),
                            Text(
                              'VOLTAR AO INÍCIO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                                color: context.onBackground,
                              ),
                            ),
                          ],
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

  String _formatVolume(double volume) {
    final intPart = volume.toInt();
    final s = intPart.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Widget _buildFinishStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.08),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: context.onSurface,
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: context.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  void _showMusicBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const WorkoutMusicPanel(),
    );
  }

  void _showAddReferenceBottomSheet(BuildContext context, Exercise ex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
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
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Referência salva com sucesso!')),
            );
          }
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(restTimerProvider);
    final resting = timerState.isActive;
    final restLeft = timerState.remainingSeconds;
    final restTotal = timerState.totalSeconds;

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
      onPopInvokedWithResult: (didPop, result) async {
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
        if (ok == true && context.mounted) Navigator.of(context).pop(result);
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
            if (resting)
              _RestBanner(
                left: restLeft,
                total: restTotal,
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
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: context.onSurface),
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
                        color: context.cardColor,
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
                                            : context.onBackground,
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
                              style: TextStyle(
                                color: context.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down_rounded,
                                color: context.onSurface, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: context.onSurface),
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
                    runSpacing: 6,
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
                      if (_max1RM > 0)
                        _BadgeTag(
                          label: 'PR: ${_max1RM.toStringAsFixed(1)} kg',
                          icon: Icons.emoji_events_rounded,
                          color: Colors.amber,
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
                          child: _BadgeTag(
                            label: 'Adicionar referência',
                            icon: Icons.add_circle_outline_rounded,
                            color: context.onSurface,
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
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.divider.withValues(alpha: 0.5)),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: context.onBackground,
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
                    _SetsList(
                      sets: _setsLogged,
                      exercise: ex,
                      onTapSeries: _showEditDeleteSeriesDialog,
                    ),
                  ],

                  // ── Inputs ────────────────────────────────────
                  const SizedBox(height: 20),
                  _InputRow(
                    serie: _currentSerie,
                    pesoCtrl: _pesoCtrl,
                    repsCtrl: _repsCtrl,
                    obsCtrl: _obsCtrl,
                    onOpenCalculator: _showPlateCalculator,
                  ),

                  // ── Modo de Execução ──
                  const SizedBox(height: 16),
                  Text(
                    'MODO DE EXECUÇÃO',
                    style: TextStyle(
                      color: context.onSurface,
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
                    Text(
                      'LADO EM EXECUÇÃO',
                      style: TextStyle(
                        color: context.onSurface,
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
                  Text(
                    'EQUIPAMENTO UTILIZADO',
                    style: TextStyle(
                      color: context.onSurface,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                   DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _equipamentoSelecionado,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: context.cardColor,
                    items: {
                      if (_equipamentoSelecionado != null &&
                          !equipmentOptions.contains(_equipamentoSelecionado))
                        _equipamentoSelecionado!,
                      ...equipmentOptions,
                    }
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
              resting: resting,
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
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.divider)),
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
                  backgroundColor: context.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text(
                  '$m:$s',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.onBackground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DESCANSO',
                style: TextStyle(
                  color: context.onSurface,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Próxima série quando pronto',
                style: TextStyle(color: context.onSurface, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: const Text('Pular'),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: context.onSurface, size: 20),
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
    double prevSessionMax1RM = 0.0;
    for (final l in logs) {
      final oneRM = l.repeticoes == 1 ? l.peso : l.peso * (1 + l.repeticoes / 30.0);
      if (oneRM > prevSessionMax1RM) {
        prevSessionMax1RM = oneRM;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÚLTIMO TREINO',
                style: TextStyle(
                  color: context.onSurface,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (prevSessionMax1RM > 0)
                Text(
                  'Max 1RM: ${prevSessionMax1RM.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
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
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'S${l.serie}: ${l.peso}kg × ${l.repeticoes}$ladoStr$eqStr',
                  style: TextStyle(
                    color: context.onBackground,
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

class _EditControllers {
  final _SetEntry entry;
  final TextEditingController pesoCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController obsCtrl;

  _EditControllers({
    required this.entry,
    required this.pesoCtrl,
    required this.repsCtrl,
    required this.obsCtrl,
  });

  void dispose() {
    pesoCtrl.dispose();
    repsCtrl.dispose();
    obsCtrl.dispose();
  }
}

class _SetsList extends StatelessWidget {
  final List<_SetEntry> sets;
  final Exercise exercise;
  final Function(int) onTapSeries;
  const _SetsList({
    required this.sets,
    required this.exercise,
    required this.onTapSeries,
  });

  @override
  Widget build(BuildContext context) {
    // Group sets by serie number, preserving insertion order
    final Map<int, List<_SetEntry>> grouped = {};
    for (final s in sets) {
      grouped.putIfAbsent(s.serie, () => []).add(s);
    }

    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(red: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SÉRIES SALVAS',
            style: TextStyle(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grouped.values.map((group) {
              final formattedText = _formatSeriesGroup(group);
              final serieNum = group.first.serie;
              return InkWell(
                onTap: () => onTapSeries(serieNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedText,
                        style: TextStyle(
                          color: context.onBackground,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.7),
                      ),
                    ],
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
  final VoidCallback? onOpenCalculator;

  const _InputRow({
    required this.serie,
    required this.pesoCtrl,
    required this.repsCtrl,
    required this.obsCtrl,
    this.onOpenCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SÉRIE $serie',
              style: TextStyle(
                color: context.onSurface,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onOpenCalculator != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.calculate_rounded,
                  size: 20,
                  color: AppColors.primaryLight,
                ),
                tooltip: 'Calculadora de Anilhas',
                onPressed: onOpenCalculator,
              ),
          ],
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
                ? context.surfaceColor.withValues(alpha: 0.6)
                : context.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: context.divider),
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: disabled
                  ? context.onSurface.withValues(alpha: 0.5)
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
    super.key,
    required this.ctrl,
    required this.label,
    this.decimal = false,
    required this.step,
  });

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
            inputFormatters: [DecimalInputFormatter()],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.onBackground,
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
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.divider)),
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.divider),
      ),
      child: Text(
        label,
        style: TextStyle(color: context.onSurface, fontSize: 11),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                color: context.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Execução: ${widget.exercise.nome}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.onBackground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Busque a execução no YouTube ou TikTok. Ao copiar o link do vídeo e retornar para o app, você poderá colar e salvar o link abaixo como referência definitiva para este exercício.',
            style: TextStyle(fontSize: 13, color: context.onSurface),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                    style: TextStyle(fontSize: 12, color: context.onBackground),
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
              labelStyle: TextStyle(color: context.onSurface),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: context.divider),
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
            style: TextStyle(color: context.onBackground),
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

// ═══════════════════════════════════════════════════════════════════

