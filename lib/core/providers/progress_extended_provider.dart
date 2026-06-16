// lib/core/providers/progress_extended_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../utils/week_utils.dart';
import '../services/notification_service.dart';
import 'providers.dart';

class GoalsNotifier extends StateNotifier<List<Goal>> {
  final AppDatabase db;
  StreamSubscription<List<Goal>>? _subscription;

  GoalsNotifier(this.db) : super([]) {
    _loadGoalsAndMigrate();
  }

  Future<void> _loadGoalsAndMigrate() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('goals_migrated_to_db') ?? false;

    if (!migrated) {
      final jsonStr = prefs.getString('workout_goals');
      if (jsonStr != null) {
        try {
          final List decoded = jsonDecode(jsonStr);
          final oldGoals = decoded.map((item) => Goal.fromJson(item)).toList();
          for (final goal in oldGoals) {
            await db.into(db.goals).insert(goal);
          }
        } catch (e) {
          debugPrint('Erro ao migrar metas do SharedPreferences para o SQLite: $e');
        }
      }
      await prefs.setBool('goals_migrated_to_db', true);
    }

    _subscription = (db.select(db.goals)
          ..orderBy([(g) => OrderingTerm.desc(g.dataCriacao)]))
        .watch()
        .listen((list) {
      state = list;
    });
  }

  Future<void> addGoal(Goal goal) async {
    await db.into(db.goals).insert(goal);
  }

  Future<void> deleteGoal(String id) async {
    await (db.delete(db.goals)..where((g) => g.id.equals(id))).go();
  }

  Future<void> toggleGoal(String id) async {
    final goal = await (db.select(db.goals)..where((g) => g.id.equals(id))).getSingleOrNull();
    if (goal != null) {
      await (db.update(db.goals)..where((g) => g.id.equals(id))).write(
        GoalsCompanion(
          concluido: Value(!goal.concluido),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalsNotifier(db);
});

// Provedor para todos os logs de exercícios concluídos
final allCompletedLogsProvider = FutureProvider<List<ExerciseLog>>((ref) async {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.exerciseLogs).join([
    drift.innerJoin(db.workoutSessions, db.workoutSessions.id.equalsExp(db.exerciseLogs.sessionId))
  ])
  ..where(db.exerciseLogs.concluido.equals(true) & db.workoutSessions.status.equals('concluido'))
  ..orderBy([drift.OrderingTerm.asc(db.exerciseLogs.data)]);

  final rows = await query.get();
  return rows.map((row) => row.readTable(db.exerciseLogs)).toList();
});

// Provedor para calcular a ofensiva (streak) de semanas consecutivas treinadas
final streakProvider = Provider<int>((ref) {
  final completedSessions = ref.watch(completedSessionsProvider).value ?? [];
  final weeklySchedule = ref.watch(weeklyScheduleProvider).value ?? [];

  // Alvo semanal de treinos (fallback para 1 se não houver agenda planejada)
  final scheduledWorkoutsCount = weeklySchedule.where((s) => s.dayId != null).length;
  final weeklyTarget = scheduledWorkoutsCount > 0 ? scheduledWorkoutsCount : 1;

  if (completedSessions.isEmpty) return 0;

  // Agrupa sessões por semana ISO (ex: "2026-W23")
  final Map<String, int> completedPerWeek = {};
  for (final session in completedSessions) {
    try {
      final date = DateTime.parse(session.data);
      final weekKey = WeekUtils.weekKeyFromDate(date);
      completedPerWeek[weekKey] = (completedPerWeek[weekKey] ?? 0) + 1;
    } catch (_) {}
  }

  int streak = 0;
  int weekIndex = 0;

  while (true) {
    final targetDate = DateTime.now().subtract(Duration(days: weekIndex * 7));
    final weekKey = WeekUtils.weekKeyFromDate(targetDate);
    final completedCount = completedPerWeek[weekKey] ?? 0;

    if (weekIndex == 0) {
      // Semana atual: se bateu a meta, conta no streak e continua descendo
      if (completedCount >= weeklyTarget) {
        streak++;
      } else {
        // Se ainda não bateu mas é a semana atual, não quebra o streak ainda.
        // Apenas continua para verificar as semanas passadas.
      }
    } else {
      // Semanas passadas: precisa ter atingido a meta semanal, senão quebra o streak
      if (completedCount >= weeklyTarget) {
        streak++;
      } else {
        break; // Ofensiva quebrada
      }
    }
    weekIndex++;
  }

  return streak;
});

// Provedor para calcular a porcentagem de evolução de cargas
final evolutionProvider = Provider<double>((ref) {
  final logs = ref.watch(allCompletedLogsProvider).value ?? [];
  if (logs.isEmpty) return 0.0;

  // Agrupa os logs por exercício (ordenados por ID/data implicitamente crescente)
  final Map<int, List<ExerciseLog>> logsPerExercise = {};
  for (final log in logs) {
    logsPerExercise.putIfAbsent(log.exerciseId, () => []).add(log);
  }

  double totalPercentageSum = 0.0;
  int exercisesCount = 0;

  logsPerExercise.forEach((exerciseId, exerciseLogs) {
    if (exerciseLogs.length < 2) return;

    // Acha o primeiro log com carga > 0
    final firstLog = exerciseLogs.firstWhere((l) => l.peso > 0, orElse: () => exerciseLogs.first);
    // Acha o último log com carga > 0
    final lastLog = exerciseLogs.lastWhere((l) => l.peso > 0, orElse: () => exerciseLogs.last);

    if (firstLog.peso > 0 && lastLog.peso > 0 && firstLog.id != lastLog.id) {
      final diff = lastLog.peso - firstLog.peso;
      final percent = (diff / firstLog.peso) * 100;
      totalPercentageSum += percent;
      exercisesCount++;
    }
  });

  if (exercisesCount == 0) return 0.0;
  return totalPercentageSum / exercisesCount;
});

// Provedor para recuperar a data de início (primeiro uso)
final firstUseDateProvider = Provider<String>((ref) {
  final completedSessions = ref.watch(completedSessionsProvider).value ?? [];
  if (completedSessions.isEmpty) return 'Hoje';

  final sorted = [...completedSessions]..sort((a, b) => a.data.compareTo(b.data));
  try {
    final firstDate = DateTime.parse(sorted.first.data);
    return '${firstDate.day.toString().padLeft(2, '0')}/${firstDate.month.toString().padLeft(2, '0')}/${firstDate.year}';
  } catch (_) {
    return 'Início';
  }
});

class MusicChannel {
  final String name;
  final String url;
  final String genre;
  MusicChannel({required this.name, required this.url, required this.genre});
}

final musicChannels = [
  MusicChannel(
    name: 'Nightwave',
    url: 'sounds/synthwave.mp3',
    genre: 'Synthwave / Vaporwave (Offline) 🌌',
  ),
  MusicChannel(
    name: 'Fluid Beats',
    url: 'sounds/lofi.mp3',
    genre: 'Chill / Lofi (Offline) ☕',
  ),
  MusicChannel(
    name: 'Rock Heavy',
    url: 'sounds/rock.mp3',
    genre: 'Heavy Metal / Hard Rock (Offline) 🎸',
  ),
];

class WorkoutMusicState {
  final bool isPlaying;
  final int currentChannelIndex;
  final bool isLoading;
  WorkoutMusicState({
    required this.isPlaying,
    required this.currentChannelIndex,
    this.isLoading = false,
  });

  WorkoutMusicState copyWith({
    bool? isPlaying,
    int? currentChannelIndex,
    bool? isLoading,
  }) {
    return WorkoutMusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentChannelIndex: currentChannelIndex ?? this.currentChannelIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkoutMusicNotifier extends StateNotifier<WorkoutMusicState> {
  final AudioPlayer _player = AudioPlayer();

  WorkoutMusicNotifier() : super(WorkoutMusicState(isPlaying: false, currentChannelIndex: 0)) {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playChannel(int index) async {
    state = state.copyWith(isLoading: true, currentChannelIndex: index);
    _updateNotification();
    try {
      await _player.stop();
      final url = musicChannels[index].url;
      await _player.play(AssetSource(url));
      state = state.copyWith(isPlaying: true, isLoading: false);
      _updateNotification();
    } catch (_) {
      state = state.copyWith(isPlaying: false, isLoading: false);
      _updateNotification();
    }
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _player.pause();
      state = state.copyWith(isPlaying: false);
      _updateNotification();
    } else {
      state = state.copyWith(isLoading: true);
      _updateNotification();
      try {
        final url = musicChannels[state.currentChannelIndex].url;
        await _player.play(AssetSource(url));
        state = state.copyWith(isPlaying: true, isLoading: false);
        _updateNotification();
      } catch (_) {
        state = state.copyWith(isPlaying: false, isLoading: false);
        _updateNotification();
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(isPlaying: false);
    NotificationService().cancelMusicNotification();
  }

  void _updateNotification() {
    final channelName = musicChannels[state.currentChannelIndex].name;
    NotificationService().showMusicNotification(channelName, state.isPlaying);
  }

  @override
  void dispose() {
    NotificationService().cancelMusicNotification();
    _player.dispose();
    super.dispose();
  }
}

final workoutMusicProvider = StateNotifierProvider<WorkoutMusicNotifier, WorkoutMusicState>((ref) {
  return WorkoutMusicNotifier();
});

// ── Insights Automáticos ───────────────────────────────────────────────────────

class WorkoutInsight {
  final String text;
  final IconData icon;
  final Color color;
  final String type; // "positive" | "warning" | "neutral"

  WorkoutInsight({
    required this.text,
    required this.icon,
    required this.color,
    required this.type,
  });
}

final automaticInsightsProvider = Provider<List<WorkoutInsight>>((ref) {
  final logs = ref.watch(allCompletedLogsProvider).value ?? [];
  final exercises = ref.watch(allExercisesProvider).value ?? [];

  final List<WorkoutInsight> insights = [];

  // 1. Boas-vindas ou mensagens de incentivo se houver poucos ou nenhum treino
  final completedSessions = logs.map((l) => l.sessionId).toSet().length;

  if (completedSessions == 0) {
    insights.add(WorkoutInsight(
      text: 'Bem-vindo ao Mete Marcha! Inicie e conclua seu primeiro treino para começar a gerar insights automáticos de volume, recordes e consistência. 🚀',
      icon: Icons.rocket_launch_rounded,
      color: Colors.cyanAccent,
      type: 'neutral',
    ));
    return insights;
  } else if (completedSessions == 1) {
    insights.add(WorkoutInsight(
      text: 'Primeiro treino concluído! Excelente começo. Continue treinando para liberar as análises comparativas e recordes históricos. ⚡',
      icon: Icons.celebration_rounded,
      color: Colors.amberAccent,
      type: 'positive',
    ));
  }

  if (exercises.isEmpty) return insights;

  final now = DateTime.now();

  // Mapear exercícios por ID
  final Map<int, Exercise> exerciseMap = {for (final e in exercises) e.id: e};

  // 2. Inatividade de grupos musculares (Não treina X há Y dias)
  final muscleGroups = exercises.map((e) => e.grupoMuscular).toSet();
  for (final muscle in muscleGroups) {
    final muscleLogs = logs.where((l) {
      final ex = exerciseMap[l.exerciseId];
      return ex != null && ex.grupoMuscular == muscle;
    }).toList();

    if (muscleLogs.isNotEmpty) {
      // Ordena decrescente por data para pegar o mais recente
      muscleLogs.sort((a, b) => b.data.compareTo(a.data));
      try {
        final lastDate = DateTime.parse(muscleLogs.first.data);
        final days = now.difference(lastDate).inDays;
        if (days >= 8) {
          insights.add(WorkoutInsight(
            text: 'Você não treina $muscle há $days dias. Que tal treinar hoje?',
            icon: Icons.calendar_today_rounded,
            color: Colors.orangeAccent,
            type: 'warning',
          ));
        }
      } catch (_) {}
    }
  }

  // 3. Novo recorde de carga nas últimas sessões (últimos 7 dias) vs histórico
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final Map<int, double> maxWeightBefore = {};
  final Map<int, double> maxWeightRecent = {};

  for (final log in logs) {
    try {
      final logDate = DateTime.parse(log.data);
      if (logDate.isBefore(sevenDaysAgo)) {
        final currentMax = maxWeightBefore[log.exerciseId] ?? 0.0;
        if (log.peso > currentMax) {
          maxWeightBefore[log.exerciseId] = log.peso;
        }
      } else {
        final currentMax = maxWeightRecent[log.exerciseId] ?? 0.0;
        if (log.peso > currentMax) {
          maxWeightRecent[log.exerciseId] = log.peso;
        }
      }
    } catch (_) {}
  }

  maxWeightRecent.forEach((exerciseId, recentMax) {
    final historicMax = maxWeightBefore[exerciseId] ?? 0.0;
    if (historicMax > 0 && recentMax > historicMax) {
      final ex = exerciseMap[exerciseId];
      if (ex != null) {
        final diff = recentMax - historicMax;
        insights.add(WorkoutInsight(
          text: 'Novo recorde no ${ex.nome}! +${diff.toStringAsFixed(0)} kg (atingiu ${recentMax.toStringAsFixed(0)} kg).',
          icon: Icons.emoji_events_rounded,
          color: Colors.amber,
          type: 'positive',
        ));
      }
    }
  });

  // 4. Comparação de Volume Semanal por Grupo Muscular (Semana Atual vs Anterior)
  final currentWeek = WeekUtils.currentWeekKey();
  final lastWeek = WeekUtils.weekKeyFromDate(now.subtract(const Duration(days: 7)));

  final Map<String, double> currentVolume = {};
  final Map<String, double> lastWeekVolume = {};

  for (final log in logs) {
    final ex = exerciseMap[log.exerciseId];
    if (ex == null) continue;

    try {
      final logDate = DateTime.parse(log.data);
      final weekKey = WeekUtils.weekKeyFromDate(logDate);
      final vol = log.peso * log.repeticoes * (ex.isUnilateral && log.lado == 'ambos' ? 2 : 1);

      if (weekKey == currentWeek) {
        currentVolume[ex.grupoMuscular] = (currentVolume[ex.grupoMuscular] ?? 0.0) + vol;
      } else if (weekKey == lastWeek) {
        lastWeekVolume[ex.grupoMuscular] = (lastWeekVolume[ex.grupoMuscular] ?? 0.0) + vol;
      }
    } catch (_) {}
  }

  currentVolume.forEach((muscle, curVol) {
    final prevVol = lastWeekVolume[muscle] ?? 0.0;
    if (prevVol > 0) {
      final diffPercent = ((curVol - prevVol) / prevVol) * 100;
      if (diffPercent >= 5) {
        insights.add(WorkoutInsight(
          text: 'Evolução no volume de $muscle: +${diffPercent.toStringAsFixed(0)}% esta semana!',
          icon: Icons.trending_up_rounded,
          color: Colors.greenAccent,
          type: 'positive',
        ));
      } else if (diffPercent <= -20) {
        insights.add(WorkoutInsight(
          text: 'Queda no volume de $muscle: ${diffPercent.toStringAsFixed(0)}% esta semana.',
          icon: Icons.trending_down_rounded,
          color: Colors.redAccent,
          type: 'warning',
        ));
      }
    }
  });

  return insights;
});
