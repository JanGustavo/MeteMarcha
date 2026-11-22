import '../../core/media/social_video_card.dart';
import '../../core/media/social_video.dart';
import '../../core/media/reference_image.dart';
import '../squads/workout_report.dart';
import '../squads/squads_page.dart';
import '../../core/services/squad_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/constants/equipment_options.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/widgets/achievement_unlock_overlay.dart';
import 'package:gym_tracker/core/providers/rest_timer_provider.dart';
import 'package:gym_tracker/core/services/audio_service.dart';
import 'package:gym_tracker/core/services/notification_service.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/week_utils.dart';
import 'package:gym_tracker/pages/workout/widgets/plate_calculator_dialog.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_music_panel.dart';
import 'package:gym_tracker/core/services/health_connect_service.dart';
import 'package:gym_tracker/pages/progress/workout_session_detail_page.dart';
import 'package:gym_tracker/pages/progress/exercise_comparison_page.dart';
import 'package:gym_tracker/pages/workout/models/workout_set_entry.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_rest_banner.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_previous_performance.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_set_edit_controllers.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_sets_list.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_set_input.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_number_field.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_action_bar.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_info_chip.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_badge_tag.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_reference_panel.dart';

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

class _WorkoutPageState extends ConsumerState<WorkoutPage>
    with WidgetsBindingObserver {
  // ── Exercise list ───────────────────────────────────────────────
  List<Exercise> _exercises = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _hasOtherUncompleted = false;

  // ── Set tracking ────────────────────────────────────────────────
  int _currentSerie = 1;
  final List<WorkoutSetEntry> _setsLogged = [];
  List<ExerciseLog> _prevLogs = []; // último treino deste exercício
  double _max1RM = 0.0; // recorde máximo 1RM histórico do exercício
  ExerciseLog?
      _max1RMLog; // registro do recorde máximo 1RM histórico do exercício

  // ── Inputs ──────────────────────────────────────────────────────
  final _pesoCtrl = TextEditingController(text: '0');
  final _repsCtrl = TextEditingController(text: '10');
  final _obsCtrl = TextEditingController();
  String _lado = 'ambos';
  String? _equipamentoSelecionado;
  bool _executandoUnilateral = false;

  double? _currentRpe;
  int? _currentRir;

  int? _lastLoadedExerciseId;

  // ── Session timer ───────────────────────────────────────────────
  int _sessionSecs = 0;
  Timer? _sessionTimer;
  StreamSubscription? _overlaySubscription;
  Stream<dynamic>? _globalOverlayStream;
  ReceivePort? _workoutMainPort;
  double _sessionVolume = 0.0;
  double? _prevSessionVolume;
  final GlobalKey _shareCardKey = GlobalKey();

  // ── Lifecycle ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.requestPermission();
    _loadExercises();
    _initSessionDuration().whenComplete(() {
      _startSessionTimer();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restTimerProvider.notifier).setInWorkoutPage(true);
    });

    if (!kIsWeb && Platform.isAndroid) {
      _fecharOverlay();

      // Registrar ReceivePort para receber ações do overlay via Dart ports (IsolateNameServer)
      // Isso ignora desconexões de FlutterJNI/EventChannel quando o app está em background
      _workoutMainPort = ReceivePort();
      ui.IsolateNameServer.removePortNameMapping('workout_main_port');
      ui.IsolateNameServer.registerPortWithName(
        _workoutMainPort!.sendPort,
        'workout_main_port',
      );
      _workoutMainPort!.listen((event) async {
        if (event == null) return;
        debugPrint(
          '[WorkoutPage] Recebeu evento do overlay via IsolatePort: $event',
        );
        try {
          final Map<String, dynamic> msg = event is Map
              ? Map<String, dynamic>.from(event)
              : Map<String, dynamic>.from(jsonDecode(event.toString()));
          await _processarMensagemOverlay(msg);
        } catch (e) {
          debugPrint(
            '[WorkoutPage] Erro ao processar mensagem via IsolatePort: $e',
          );
        }
      });

      if (_globalOverlayStream == null) {
        _globalOverlayStream =
            FlutterOverlayWindow.overlayListener.asBroadcastStream();
        _globalOverlayStream!.listen(
          (_) {},
        ); // Dummy listener to keep underlying subscription alive
      }
      _overlaySubscription = _globalOverlayStream!.listen((event) async {
        if (event == null) return;
        debugPrint(
          '[WorkoutPage] Recebeu evento do overlay via channel: $event',
        );
        try {
          final Map<String, dynamic> msg = event is Map
              ? Map<String, dynamic>.from(event)
              : Map<String, dynamic>.from(jsonDecode(event.toString()));
          await _processarMensagemOverlay(msg);
        } catch (e) {
          debugPrint(
            '[WorkoutPage] Erro ao processar mensagem do overlay via channel: $e',
          );
        }
      });
    }
  }

  Future<void> _processarMensagemOverlay(Map<String, dynamic> msg) async {
    final type = msg['type'];
    debugPrint('[WorkoutPage] Processando acao do overlay: $type');
    if (type == 'save_series') {
      final double peso = (msg['peso'] as num).toDouble();
      final int reps = msg['reps'] as int;
      debugPrint('[WorkoutPage] save_series -> peso: $peso, reps: $reps');

      _pesoCtrl.text = peso.toString();
      _repsCtrl.text = reps.toString();

      await _salvarSerie();
      await _enviarEstadoParaOverlay();
    } else if (type == 'next_exercise') {
      debugPrint('[WorkoutPage] next_exercise');
      await _proximoExercicio();
      await _enviarEstadoParaOverlay();
    } else if (type == 'select_exercise') {
      final int index = msg['index'] as int;
      debugPrint('[WorkoutPage] select_exercise -> index: $index');
      await _selecionarExercicio(index);
      await _enviarEstadoParaOverlay();
    } else if (type == 'open_app') {
      debugPrint('[WorkoutPage] open_app');
      FlutterForegroundTask.launchApp();
      await FlutterOverlayWindow.closeOverlay();
    } else if (type == 'close_overlay') {
      debugPrint('[WorkoutPage] close_overlay');
      await FlutterOverlayWindow.closeOverlay();
    } else if (type == 'stop_rest_timer') {
      debugPrint('[WorkoutPage] stop_rest_timer');
      ref.read(restTimerProvider.notifier).cancelRest();
      await _enviarEstadoParaOverlay();
    }
  }

  Future<void> _initSessionDuration() async {
    try {
      final db = ref.read(databaseProvider);
      final session = await (db.select(
        db.workoutSessions,
      )..where((s) => s.id.equals(widget.sessionId)))
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
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    if (!kIsWeb && Platform.isAndroid) {
      ui.IsolateNameServer.removePortNameMapping('workout_main_port');
      _workoutMainPort?.close();
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
    _sessionTimer?.cancel();
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    _obsCtrl.dispose();
    try {
      ref.read(restTimerProvider.notifier).setInWorkoutPage(false);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb || !Platform.isAndroid) return;
    if (state == AppLifecycleState.paused) {
      _ativarOverlaySePermitido();
    } else if (state == AppLifecycleState.resumed) {
      _fecharOverlay();
    }
  }

  Future<void> _ativarOverlaySePermitido() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_exercises.isEmpty) return;
    try {
      final isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        return;
      }
      final isActive = await FlutterOverlayWindow.isActive();
      if (!mounted) return;
      if (!isActive) {
        final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
        await FlutterOverlayWindow.showOverlay(
          alignment: OverlayAlignment.center,
          height: (76 * pixelRatio).round(),
          width: (76 * pixelRatio).round(),
          enableDrag: false,
          overlayTitle: 'Mete Marcha Fit',
          overlayContent: 'Painel Flutuante do Treino',
          flag: OverlayFlag.focusPointer,
        );
      }
      await _enviarEstadoParaOverlay();
    } catch (e) {
      debugPrint('Erro ao ativar overlay: $e');
    }
  }

  Future<void> _fecharOverlay() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Erro ao fechar overlay: $e');
    }
  }

  Future<void> _enviarEstadoParaOverlay() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final isOverlayActive = await FlutterOverlayWindow.isActive();
      if (!isOverlayActive) return;

      final timerState = ref.read(restTimerProvider);
      final completedLogs =
          await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
      final completedIds = completedLogs.map((l) => l.exerciseId).toSet();

      final exercisesList = _exercises.map((e) => e.nome).toList();
      final exercisesCompleted =
          _exercises.map((e) => completedIds.contains(e.id)).toList();

      final data = {
        'type': 'state_update',
        'exerciseName': _current.nome,
        'weight': double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0.0,
        'reps': int.tryParse(_repsCtrl.text) ?? 10,
        'exerciseIndex': _currentIndex,
        'exercises': exercisesList,
        'exercisesCompleted': exercisesCompleted,
        'currentSerie': _currentSerie,
        'timerSeconds': timerState.remainingSeconds,
        'timerMax': timerState.totalSeconds,
        'isResting': timerState.isActive,
      };

      // Tenta enviar via IsolateNameServer
      final sendPort = ui.IsolateNameServer.lookupPortByName(
        'workout_overlay_port',
      );
      if (sendPort != null) {
        debugPrint('[WorkoutPage] Enviando estado via IsolatePort');
        sendPort.send(data);
      } else {
        debugPrint('[WorkoutPage] IsolatePort do overlay nao encontrado');
      }

      // Mantém envio via shareData por compatibilidade
      await FlutterOverlayWindow.shareData(data);
    } catch (e) {
      debugPrint('Erro ao enviar estado para overlay: $e');
    }
  }

  Future<void> _selecionarExercicio(int index) async {
    if (index >= 0 && index < _exercises.length) {
      setState(() {
        _currentIndex = index;
      });
      await _loadExerciseContext();
    }
  }

  // ── Data loading ────────────────────────────────────────────────

  Future<void> _loadExercises() async {
    final exs =
        await ref.read(exerciseDaoProvider).getExercisesForDay(widget.dayId);
    if (!mounted) return;

    int initialIndex = 0;
    try {
      final currentLogs =
          await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
      if (!mounted) return;
      if (currentLogs.isNotEmpty) {
        final sortedLogs = List<ExerciseLog>.from(currentLogs)
          ..sort((a, b) => a.id.compareTo(b.id));
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

    // Carrega o volume do treino anterior para comparar
    double? prevVol;
    try {
      final prevSession = await ref
          .read(workoutDaoProvider)
          .getPreviousCompletedSession(widget.dayId, widget.sessionId);
      if (!mounted) return;
      if (prevSession != null) {
        final prevLogs =
            await ref.read(logDaoProvider).getLogsForSession(prevSession.id);
        if (!mounted) return;
        prevVol = prevLogs.fold<double>(
          0.0,
          (sum, log) => sum + (log.peso * log.repeticoes),
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar volume do treino anterior: $e');
    }

    setState(() {
      _exercises = exs;
      _currentIndex = initialIndex;
      _prevSessionVolume = prevVol;
      _loading = false;
    });
    if (exs.isNotEmpty) await _loadExerciseContext();
  }

  Future<void> _loadExerciseContext() async {
    if (_exercises.isEmpty) return;
    final ex = _current;

    // Busca desempenho do último treino para pré-preencher os campos (excluindo a sessão atual)
    final prev = await ref
        .read(logDaoProvider)
        .getLastLogsForExercise(ex.id, excludeSessionId: widget.sessionId);
    if (!mounted) return;

    // Busca recorde máximo 1RM histórico
    final prevMax1RM =
        await ref.read(logDaoProvider).getMax1RMForExercise(ex.id);
    if (!mounted) return;
    final prevMax1RMLog =
        await ref.read(logDaoProvider).getMax1RMLogForExercise(ex.id);
    if (!mounted) return;

    // Busca logs já realizados na sessão atual para este exercício
    final currentLogs =
        await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
    if (!mounted) return;
    final exerciseSessionLogs =
        currentLogs.where((l) => l.exerciseId == ex.id).toList();

    final completedIds = currentLogs.map((l) => l.exerciseId).toSet();
    final hasOtherUncompleted = _exercises.asMap().entries.any(
          (entry) =>
              entry.key != _currentIndex &&
              !completedIds.contains(entry.value.id),
        );

    final isBodyWeight = ex.equipamento.trim().toLowerCase() == 'peso corporal';

    // Busca o peso do perfil diretamente do banco de dados (evita race conditions com providers reativos em carregamento)
    final profile = await ref.read(profileDaoProvider).getProfile();
    if (!mounted) return;
    final userWeight = profile?.pesoAtual ?? 70.0;

    final exerciseChanged = _lastLoadedExerciseId != ex.id;
    _lastLoadedExerciseId = ex.id;

    setState(() {
      _hasOtherUncompleted = hasOtherUncompleted;
      _max1RM = prevMax1RM;
      _max1RMLog = prevMax1RMLog;
      _prevLogs = prev;
      _sessionVolume = currentLogs.fold<double>(
        0.0,
        (sum, log) => sum + (log.peso * log.repeticoes),
      );
      final numUniqueSeries =
          exerciseSessionLogs.map((l) => l.serie).toSet().length;
      _currentSerie = numUniqueSeries + 1;
      _currentRpe = null;
      _currentRir = null;
      _setsLogged.clear();
      _setsLogged.addAll(
        exerciseSessionLogs.map(
          (l) => WorkoutSetEntry(
            id: l.id,
            serie: l.serie,
            peso: l.peso,
            reps: l.repeticoes,
            lado: l.lado,
            equipamento: l.equipamento,
            observacoes: l.observacoes,
            rpe: l.rpe,
            rir: l.rir,
          ),
        ),
      );
      _lado = 'ambos';
      _executandoUnilateral = ex.isUnilateral;
      if (exerciseChanged) {
        if (exerciseSessionLogs.isNotEmpty) {
          _equipamentoSelecionado =
              exerciseSessionLogs.last.equipamento ?? ex.equipamento;
        } else {
          _equipamentoSelecionado = ex.equipamento;
        }
      } else {
        _equipamentoSelecionado ??= (exerciseSessionLogs.isNotEmpty
            ? (exerciseSessionLogs.last.equipamento ?? ex.equipamento)
            : ex.equipamento);
      }

      if (exerciseSessionLogs.isNotEmpty) {
        final lastPeso = exerciseSessionLogs.last.peso;
        _pesoCtrl.text = lastPeso % 1 == 0
            ? lastPeso.toInt().toString()
            : lastPeso.toString();
        _repsCtrl.text = exerciseSessionLogs.last.repeticoes.toString();
      } else if (prev.isNotEmpty) {
        final totalPeso =
            prev.map((l) => l.peso).fold<double>(0.0, (a, b) => a + b);
        final totalReps =
            prev.map((l) => l.repeticoes).fold<int>(0, (a, b) => a + b);
        double avgPeso = ((totalPeso / prev.length) * 2).round() / 2.0;
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
      if (nome.contains('flexão') ||
          nome.contains('pushup') ||
          nome.contains('push-up')) {
        pct = 65;
      } else if (grupo == 'core' ||
          nome.contains('abdominal') ||
          nome.contains('prancha') ||
          nome.contains('crunch')) {
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
    if (nome.contains('flexão') ||
        nome.contains('pushup') ||
        nome.contains('push-up')) {
      if (!nome.contains('quadril') &&
          !nome.contains('plantar') &&
          !nome.contains('perna') &&
          !nome.contains('joelho')) {
        return pesoUsuario * 0.65;
      }
    }

    // 2. Abdominais / Core (Crunches, prancha)
    if (grupo == 'core' ||
        nome.contains('abdominal') ||
        nome.contains('prancha') ||
        nome.contains('crunch')) {
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
  bool get _isLast => !_hasOtherUncompleted;

  double _getWeightStep() {
    if (_exercises.isEmpty) return 0.5;
    final ex = _current;
    final equip =
        (_equipamentoSelecionado ?? ex.equipamento).trim().toLowerCase();
    final muscle = ex.grupoMuscular.trim().toLowerCase();
    final isUnilateral = _executandoUnilateral;

    final isLegs = muscle.contains('perna') ||
        muscle.contains('coxa') ||
        muscle.contains('gluteo') ||
        muscle.contains('quadriceps') ||
        muscle.contains('isquiotibiais') ||
        muscle.contains('panturrilha') ||
        muscle.contains('leg');

    final isLargeUpper = muscle.contains('costas') ||
        muscle.contains('dorsal') ||
        muscle.contains('back') ||
        muscle.contains('peito') ||
        muscle.contains('peitorais') ||
        muscle.contains('chest');

    if (equip.contains('máquina') ||
        equip.contains('maquina') ||
        equip.contains('cabo') ||
        equip.contains('smith') ||
        equip.contains('polia')) {
      if (isLegs) {
        return 10.0;
      } else {
        return 5.0;
      }
    }

    if (isLegs) {
      return isUnilateral ? 5.0 : 10.0;
    } else if (isLargeUpper) {
      return isUnilateral ? 2.0 : 5.0;
    } else {
      return isUnilateral ? 1.0 : 2.0;
    }
  }

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

  void _showPrCelebration(
    double peso,
    int reps,
    double new1RM,
    double prevMax1RM,
  ) {
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
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.yellowAccent,
              size: 36,
            ),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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
          initialWeight:
              double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 60.0,
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
    debugPrint(
      '[WorkoutPage] _salvarSerie -> peso parsed: $peso, reps parsed: $reps',
    );

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
    final Value<String?> valueObs =
        obs.isNotEmpty ? Value<String?>(obs) : const Value<String?>.absent();

    final double new1RM = reps == 1 ? peso : peso * (1 + reps / 30.0);
    final double prevMax1RM = _max1RM;
    final bool isPR = prevMax1RM > 0 && new1RM > prevMax1RM;

    final List<int> insertedIds = [];
    try {
      if (_executandoUnilateral && _lado == 'ambos') {
        // Grava dois logs: esquerdo e direito
        for (final l in ['esquerdo', 'direito']) {
          final id = await logDao.insertLog(
            ExerciseLogsCompanion.insert(
              exerciseId: _current.id,
              sessionId: widget.sessionId,
              data: now,
              peso: peso,
              repeticoes: reps,
              serie: Value(_currentSerie),
              lado: Value(l),
              equipamento: Value(_equipamentoSelecionado),
              observacoes: valueObs,
              rpe: _currentRpe != null
                  ? Value(_currentRpe)
                  : const Value.absent(),
              rir: _currentRir != null
                  ? Value(_currentRir)
                  : const Value.absent(),
            ),
          );
          insertedIds.add(id);
        }
      } else {
        final id = await logDao.insertLog(
          ExerciseLogsCompanion.insert(
            exerciseId: _current.id,
            sessionId: widget.sessionId,
            data: now,
            peso: peso,
            repeticoes: reps,
            serie: Value(_currentSerie),
            lado: Value(_lado),
            equipamento: Value(_equipamentoSelecionado),
            observacoes: valueObs,
            rpe:
                _currentRpe != null ? Value(_currentRpe) : const Value.absent(),
            rir:
                _currentRir != null ? Value(_currentRir) : const Value.absent(),
          ),
        );
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
          _max1RMLog = ExerciseLog(
            id: insertedIds[0],
            exerciseId: _current.id,
            sessionId: widget.sessionId,
            data: DateTime.now().toIso8601String(),
            peso: peso,
            repeticoes: reps,
            serie: _currentSerie,
            lado: _lado,
            concluido: true,
            equipamento: _equipamentoSelecionado,
            observacoes: obs.isNotEmpty ? obs : null,
            rpe: _currentRpe,
            rir: _currentRir,
          );
        }
      }
      if (_executandoUnilateral && _lado == 'ambos') {
        _setsLogged.add(
          WorkoutSetEntry(
            id: insertedIds[0],
            serie: _currentSerie,
            peso: peso,
            reps: reps,
            lado: 'esquerdo',
            equipamento: _equipamentoSelecionado,
            observacoes: obs.isNotEmpty ? obs : null,
            rpe: _currentRpe,
            rir: _currentRir,
          ),
        );
        _setsLogged.add(
          WorkoutSetEntry(
            id: insertedIds[1],
            serie: _currentSerie,
            peso: peso,
            reps: reps,
            lado: 'direito',
            equipamento: _equipamentoSelecionado,
            observacoes: obs.isNotEmpty ? obs : null,
            rpe: _currentRpe,
            rir: _currentRir,
          ),
        );
      } else {
        _setsLogged.add(
          WorkoutSetEntry(
            id: insertedIds[0],
            serie: _currentSerie,
            peso: peso,
            reps: reps,
            lado: _lado,
            equipamento: _equipamentoSelecionado,
            observacoes: obs.isNotEmpty ? obs : null,
            rpe: _currentRpe,
            rir: _currentRir,
          ),
        );
      }
      _currentSerie++;
      _currentRpe = null;
      _currentRir = null;
    });

    _startRestTimer(_current.tempoDescansoSegundos);

    final expectedSets = _obterSeriesEsperadas(_current.volume);
    final completedSets = _setsLogged.map((e) => e.serie).toSet().length;
    if (expectedSets != null && completedSets >= expectedSets) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
    final entriesToDelete =
        _setsLogged.where((e) => e.serie == serieNum).toList();

    for (final entry in entriesToDelete) {
      if (entry.id != null) {
        await logDao.deleteLog(entry.id!);
      }
    }

    // Re-sequenciar as séries seguintes no banco
    final dbLogs = await logDao.getLogsForSession(widget.sessionId);
    final exerciseLogs =
        dbLogs.where((l) => l.exerciseId == _current.id).toList();
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
      final pesoStr = entry.peso % 1 == 0
          ? entry.peso.toInt().toString()
          : entry.peso.toString();
      return WorkoutSetEditControllers(
        entry: entry,
        pesoCtrl: TextEditingController(text: pesoStr),
        repsCtrl: TextEditingController(text: entry.reps.toString()),
        obsCtrl: TextEditingController(text: entry.observacoes ?? ''),
        equipamento: entry.equipamento ?? _current.equipamento,
      );
    }).toList();

    final isDark = context.isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, dialogState) {
            return AlertDialog(
              backgroundColor: context.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      size: 24,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Editar Série $serieNum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
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
                              : AppColors.lightBackground.withValues(
                                  alpha: 0.5,
                                ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isEsquerdo
                                              ? AppColors.info
                                              : AppColors.success)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEsquerdo
                                              ? Icons
                                                  .keyboard_arrow_left_rounded
                                              : Icons
                                                  .keyboard_arrow_right_rounded,
                                          size: 14,
                                          color: isEsquerdo
                                              ? AppColors.info
                                              : AppColors.success,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          isEsquerdo ? 'ESQUERDO' : 'DIREITO',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isEsquerdo
                                                ? AppColors.info
                                                : AppColors.success,
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
                            WorkoutNumberField(
                              ctrl: c.pesoCtrl,
                              label: 'Peso (kg)',
                              decimal: true,
                              step: _getWeightStep(),
                            ),
                            const SizedBox(height: 12),
                            WorkoutNumberField(
                              ctrl: c.repsCtrl,
                              label: 'Repetições',
                              step: 1.0,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: c.equipamento,
                              decoration: const InputDecoration(
                                labelText: 'Equipamento',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                prefixIcon: Icon(
                                  Icons.fitness_center_rounded,
                                  size: 20,
                                ),
                              ),
                              dropdownColor: context.cardColor,
                              items: {
                                if (c.equipamento != null &&
                                    !equipmentOptions.contains(
                                      c.equipamento,
                                    ))
                                  c.equipamento!,
                                ...equipmentOptions,
                              }
                                  .map(
                                    (option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                dialogState(() {
                                  c.equipamento = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: c.obsCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Observações',
                                labelStyle: TextStyle(fontSize: 12),
                                prefixIcon: Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
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
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (cConfirm) => AlertDialog(
                            backgroundColor: context.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text('Excluir Série?'),
                              ],
                            ),
                            content: const Text(
                              'Tem certeza que deseja excluir esta série de forma permanente?',
                            ),
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
                          Navigator.pop(ctx);
                          await _deletarSerie(serieNum);
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Excluir',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            // Validação e Salvamento
                            final logDao = ref.read(logDaoProvider);
                            for (final c in controllers) {
                              final peso = double.tryParse(
                                    c.pesoCtrl.text.replaceAll(',', '.'),
                                  ) ??
                                  0.0;
                              final reps = int.tryParse(c.repsCtrl.text) ?? 0;
                              final obs = c.obsCtrl.text.trim();
                              final equip = c.equipamento;
                              if (reps <= 0 || peso <= 0) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Carga e repetições devem ser maiores que zero.',
                                      ),
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
                                  equipamento: equip,
                                );
                              }
                            }
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            await _loadExerciseContext();
                          },
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
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
      final logDao = ref.read(logDaoProvider);
      final currentLogs = await logDao.getLogsForSession(widget.sessionId);
      final completedIds = currentLogs.map((l) => l.exerciseId).toSet();

      int nextUncompletedIndex = -1;
      for (int step = 1; step < _exercises.length; step++) {
        final idx = (_currentIndex + step) % _exercises.length;
        if (!completedIds.contains(_exercises[idx].id)) {
          nextUncompletedIndex = idx;
          break;
        }
      }

      if (nextUncompletedIndex != -1) {
        setState(() {
          _currentIndex = nextUncompletedIndex;
        });
        await _loadExerciseContext();
      } else {
        await _confirmarFinalizarTreino();
      }
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
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Exercícios Pendentes')),
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
                        border: Border.all(color: context.divider, width: 1),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.12,
                                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.divider,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                  color: context.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
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
      final allSessionLogs =
          await ref.read(logDaoProvider).getLogsForSession(widget.sessionId);
      totalVolume = allSessionLogs.fold<double>(
        0.0,
        (sum, log) => sum + (log.peso * log.repeticoes),
      );
      uniqueExercisesCount =
          allSessionLogs.map((log) => log.exerciseId).toSet().length;
      totalSetsCount = allSessionLogs
          .map((log) => '${log.exerciseId}_${log.serie}')
          .toSet()
          .length;
    } catch (e) {
      debugPrint('Erro ao calcular estatísticas do treino: $e');
    }

    // Salva conquistas pré-finalização para detectar novos desbloqueios
    final prevAchievements = ref.read(achievementsStatusProvider);

    await ref
        .read(workoutDaoProvider)
        .finishSession(widget.sessionId, _sessionSecs);

    // Aguarda atualização assíncrona nos streams do Riverpod
    await Future.delayed(const Duration(milliseconds: 250));
    final nextAchievements = ref.read(achievementsStatusProvider);

    final newlyUnlocked = <AchievementStatus>[];
    for (int i = 0; i < prevAchievements.length; i++) {
      final prev = prevAchievements[i];
      final next = nextAchievements[i];
      if (next.unlockedLevelIndex > prev.unlockedLevelIndex) {
        newlyUnlocked.add(next);
      }
    }

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

    WorkoutSession? completedSession;
    try {
      final db = ref.read(databaseProvider);
      completedSession = await (db.select(
        db.workoutSessions,
      )..where((s) => s.id.equals(widget.sessionId)))
          .getSingleOrNull();
    } catch (e) {
      debugPrint('Erro ao recuperar sessao finalizada: $e');
    }

    if (!mounted) return;

    // Dispara animações sequenciais de conquistas desbloqueadas
    if (newlyUnlocked.isNotEmpty) {
      int delayMs = 500;
      for (final status in newlyUnlocked) {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) {
            AchievementUnlockOverlay.show(context, status);
          }
        });
        delayMs += 5000;
      }
    }

    _showFinishDialog(
      totalVolume: totalVolume,
      uniqueExercises: uniqueExercisesCount,
      totalSets: totalSetsCount,
      completedSession: completedSession,
    );
  }

  Future<void> _shareWorkoutAsImage() async {
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/metemacha_treino.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Mais um treino concluído! Mete Marcha! 🔥💪',
        ),
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar imagem: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showFinishDialog({
    required double totalVolume,
    required int uniqueExercises,
    required int totalSets,
    required WorkoutSession? completedSession,
  }) {
    final isDark = context.isDark;
    final Widget? volumeCompareWidget;
    if (_prevSessionVolume != null && _prevSessionVolume! > 0) {
      final diff = totalVolume - _prevSessionVolume!;
      final percent = (diff / _prevSessionVolume!) * 100;
      final isOverload = diff > 0;

      volumeCompareWidget = Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOverload
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 11,
              color: isOverload ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(width: 2),
            Text(
              isOverload
                  ? '+${diff.toStringAsFixed(0)} kg (+${percent.toStringAsFixed(1)}%)'
                  : '${diff.toStringAsFixed(0)} kg (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isOverload ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ],
        ),
      );
    } else {
      volumeCompareWidget = null;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.9),
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RepaintBoundary(
                      key: _shareCardKey,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.cardColor,
                              context.cardColor.withValues(alpha: 0.95),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
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
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
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
                                    value: WeekUtils.formatDuration(
                                      _sessionSecs,
                                    ),
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
                                    value:
                                        '${totalVolume.toStringAsFixed(0)} kg',
                                    extra: volumeCompareWidget,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (completedSession != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FilledButton.icon(
                              icon: const Icon(Icons.groups_outlined),
                              label: const Text('Publicar relatório no squad'),
                              onPressed: () async {
                                try {
                                  final report = await snapshotWorkout(
                                      ref.read(databaseProvider),
                                      completedSession);
                                  if ((report['sets'] as List).isEmpty)
                                    throw Exception(
                                        'Não há execuções para compartilhar.');
                                  final cover = await reportCover(report);
                                  if (!mounted) return;
                                  await Navigator.of(this.context).push(
                                      MaterialPageRoute(
                                          builder: (_) => StoryComposer(
                                              api: SquadService(),
                                              initialPhoto: cover,
                                              report: report)));
                                } catch (e) {
                                  if (mounted)
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(SnackBar(
                                            content: Text(e.toString())));
                                }
                              })),
                    // Buttons Area
                    // 1. Compartilhar Imagem
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
                          onPressed: _shareWorkoutAsImage,
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
                              Icon(
                                Icons.image_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'COMPARTILHAR CARD (IMAGEM)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Compartilhar Texto
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final dayNameClean =
                              widget.dayName.toLowerCase().contains('treino')
                                  ? widget.dayName
                                  : 'Treino de ${widget.dayName}';
                          final durationMin = (_sessionSecs / 60).round();
                          final formattedVolume = _formatVolume(totalVolume);
                          final shareText =
                              "Meteu Marcha! 🔥 $dayNameClean concluído: $uniqueExercises ${uniqueExercises == 1 ? 'exercício' : 'exercícios'} | $durationMin min | ${formattedVolume}kg totais. #MeteMarcha";
                          SharePlus.instance.share(
                            ShareParams(text: shareText),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryLight,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_fields_rounded,
                              size: 18,
                              color: AppColors.primaryLight,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'COMPARTILHAR TEXTO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Ver Resumo
                    if (completedSession != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WorkoutSessionDetailPage(
                                  session: completedSession,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'VER RESUMO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 4. Voltar ao Início
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.12),
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
                            Icon(
                              Icons.home_rounded,
                              size: 18,
                              color: context.onBackground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VOLTAR AO INÍCIO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
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
    Widget? extra,
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
          if (extra != null) ...[const SizedBox(height: 4), extra],
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
      builder: (ctx) => WorkoutReferencePanel(
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
    ref.listen<RestTimerState>(restTimerProvider, (previous, next) {
      _enviarEstadoParaOverlay();
    });
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
                child: const Text('Continuar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
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
            if (_sessionVolume > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_sessionVolume.toStringAsFixed(0)} kg',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.music_note_rounded,
                color: AppColors.primaryLight,
              ),
              tooltip: 'Música',
              onPressed: () => _showMusicBottomSheet(context),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: _confirmarFinalizarTreino,
              icon: const Icon(
                Icons.check_rounded,
                color: AppColors.primaryLight,
                size: 18,
              ),
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
              WorkoutRestBanner(
                left: restLeft,
                total: restTotal,
                onSkip: _skipRest,
                onAdjust: (sec) =>
                    ref.read(restTimerProvider.notifier).adjustTime(sec),
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
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: context.onSurface,
                        ),
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
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    )
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
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: context.onSurface,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.onSurface,
                        ),
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
                      WorkoutInfoChip(ex.grupoMuscular),
                      if (ex.equipamento != 'Livre') ...[
                        const SizedBox(width: 6),
                        WorkoutInfoChip(ex.equipamento),
                      ],
                      if (ex.volume != null && ex.volume!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        WorkoutInfoChip(ex.volume!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Nome do exercício ──────────────────────────
                  Text(
                    ex.nome,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 26, letterSpacing: -0.5),
                  ),

                  // ── Badges ────────────────────────────────────
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (ex.isUnilateral)
                        const WorkoutBadgeTag(
                          label: 'Unilateral',
                          icon: Icons.swap_horiz_rounded,
                        ),
                      WorkoutBadgeTag(
                        label: 'Descanso ${ex.tempoDescansoSegundos}s',
                        icon: Icons.timer_rounded,
                        color: AppColors.info,
                      ),
                      if (_max1RM > 0)
                        GestureDetector(
                          onTap: () => _showPrDetailsDialog(context),
                          child: WorkoutBadgeTag(
                            label: 'PR: ${_max1RM.toStringAsFixed(1)} kg',
                            icon: Icons.emoji_events_rounded,
                            color: Colors.amber,
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciseComparisonPage(
                                initialExerciseId: ex.id,
                                initialExerciseName: ex.nome,
                              ),
                            ),
                          );
                        },
                        child: const WorkoutBadgeTag(
                          label: 'Histórico & Evolução',
                          icon: Icons.analytics_rounded,
                        ),
                      ),
                      if (ex.referenceImage != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReferenceImage(encoded: ex.referenceImage!)),
                      TextButton.icon(
                          onPressed: () async {
                            try {
                              final image = await pickReferenceImage();
                              if (image == null) return;
                              final updated = ex.copyWith(
                                  referenceImage: drift.Value(image));
                              await ref
                                  .read(exerciseDaoProvider)
                                  .updateExercise(updated);
                              if (mounted) {
                                setState(() {
                                  final index = _exercises
                                      .indexWhere((e) => e.id == ex.id);
                                  if (index >= 0) _exercises[index] = updated;
                                });
                              }
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())));
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Imagem de referência')),
                      if (ex.link != null && ex.link!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _openLink(ex.link!),
                          onLongPress: () =>
                              _showAddReferenceBottomSheet(context, ex),
                          child: const WorkoutBadgeTag(
                            label: 'Ver referência',
                            icon: Icons.play_circle_rounded,
                            color: AppColors.warning,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () =>
                              _showAddReferenceBottomSheet(context, ex),
                          child: WorkoutBadgeTag(
                            label: 'Adicionar referência',
                            icon: Icons.add_circle_outline_rounded,
                            color: context.onSurface,
                          ),
                        ),
                    ],
                  ),

                  // ── Observações / Biomecânica do Exercício ──
                  if (ex.observacoes != null &&
                      ex.observacoes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.psychology_alt_rounded,
                                size: 16,
                                color: AppColors.primaryLight,
                              ),
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
                    WorkoutPreviousPerformance(logs: _prevLogs, exercise: ex),
                  ],

                  // ── Séries já salvas nesta sessão ──────────────
                  if (_setsLogged.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    WorkoutSetsList(
                      sets: _setsLogged,
                      exercise: ex,
                      onTapSeries: _showEditDeleteSeriesDialog,
                    ),
                  ],

                  // ── Inputs ────────────────────────────────────
                  const SizedBox(height: 20),
                  WorkoutSetInput(
                    serie: _currentSerie,
                    pesoCtrl: _pesoCtrl,
                    repsCtrl: _repsCtrl,
                    obsCtrl: _obsCtrl,
                    pesoStep: _getWeightStep(),
                    onOpenCalculator: _showPlateCalculator,
                  ),
                  if (ref.watch(rpeEnabledProvider)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<double?>(
                            key: ValueKey('rpe_${ex.id}_$_currentRpe'),
                            initialValue: _currentRpe,
                            decoration: const InputDecoration(
                              labelText: 'RPE (Esforço 1-10)',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            dropdownColor: context.cardColor,
                            style: TextStyle(
                              color: context.onBackground,
                              fontSize: 14,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Nulo'),
                              ),
                              ...[
                                10.0,
                                9.5,
                                9.0,
                                8.5,
                                8.0,
                                7.5,
                                7.0,
                                6.5,
                                6.0,
                                5.5,
                                5.0,
                              ].map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(
                                    val % 1 == 0
                                        ? val.toInt().toString()
                                        : val.toString(),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _currentRpe = val;
                                if (val != null) {
                                  final calculatedRir = (10.0 - val).round();
                                  if (calculatedRir >= 0 &&
                                      calculatedRir <= 5) {
                                    _currentRir = calculatedRir;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            key: ValueKey('rir_${ex.id}_$_currentRir'),
                            initialValue: _currentRir,
                            decoration: const InputDecoration(
                              labelText: 'RIR (Repetições de Reserva)',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            dropdownColor: context.cardColor,
                            style: TextStyle(
                              color: context.onBackground,
                              fontSize: 14,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Nulo'),
                              ),
                              ...[0, 1, 2, 3, 4, 5].map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(
                                    val == 0 ? 'Falha (0 RIR)' : '$val RIR',
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _currentRir = val;
                                if (val != null) {
                                  _currentRpe = 10.0 - val;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

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
                        icon: Icon(Icons.people_rounded),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Unilateral'),
                        icon: Icon(Icons.person_rounded),
                      ),
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
                    key: ValueKey('equip_${ex.id}_$_equipamentoSelecionado'),
                    isExpanded: true,
                    initialValue: _equipamentoSelecionado,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: context.cardColor,
                    items: {
                      if (_equipamentoSelecionado != null &&
                          !equipmentOptions.contains(
                            _equipamentoSelecionado,
                          ))
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
            WorkoutActionBar(
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
      if (SocialVideo.parse(url) != null) {
        await ref.read(workoutMusicProvider.notifier).stop();
        if (!mounted) return;
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Vídeo de referência')),
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SocialVideoCard(url: url)))));
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Falha silenciosa ou log
    }
  }

  void _showPrDetailsDialog(BuildContext context) {
    final log = _max1RMLog;
    final isDark = context.isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 24,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recorde Pessoal (PR)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.amber,
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
                Text(
                  'Sua estimativa de 1RM (Força Máxima) mais alta para este exercício:',
                  style: TextStyle(color: context.onSurface, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                    children: [
                      Text(
                        '${_max1RM.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1RM Estimada (One-Rep Max)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (log != null) ...[
                  Text(
                    'Série que atingiu o recorde:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    label: 'Carga levantada:',
                    value: '${log.peso.toStringAsFixed(1)} kg',
                  ),
                  _buildDetailRow(
                    label: 'Repetições:',
                    value: '${log.repeticoes}',
                  ),
                  _buildDetailRow(
                    label: 'Série original:',
                    value: 'Série ${log.serie}',
                  ),
                  if (log.lado != 'ambos')
                    _buildDetailRow(
                      label: 'Lado:',
                      value: log.lado == 'esquerdo' ? 'Esquerdo' : 'Direito',
                    ),
                  if (log.equipamento != null)
                    _buildDetailRow(
                      label: 'Equipamento:',
                      value: log.equipamento!,
                    ),
                  _buildDetailRow(
                    label: 'Data de realização:',
                    value: _formatLogDate(log.data),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Fórmula de cálculo (Epley):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log != null && log.repeticoes == 1
                        ? '1RM = Carga (pois foi realizada 1 repetição)'
                        : '1RM = Carga × (1 + Repetições / 30)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Entendi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatLogDate(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return DateFormat('dd/MM/yyyy - HH:mm').format(parsed.toLocal());
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────
