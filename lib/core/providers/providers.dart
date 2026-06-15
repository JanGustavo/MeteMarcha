// lib/core/providers/providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../utils/week_utils.dart';
import '../services/foreground_service.dart';
import '../services/widget_sync_service.dart';
import 'progress_extended_provider.dart';

// ── Database ──────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAOs ──────────────────────────────────────────────────────────────────────

final exerciseDaoProvider = Provider<ExerciseDao>(
  (ref) => ref.watch(databaseProvider).exerciseDao,
);

final workoutDaoProvider = Provider<WorkoutDao>(
  (ref) => ref.watch(databaseProvider).workoutDao,
);

final logDaoProvider = Provider<LogDao>(
  (ref) => ref.watch(databaseProvider).logDao,
);

final profileDaoProvider = Provider<ProfileDao>(
  (ref) => ref.watch(databaseProvider).profileDao,
);

// ── Stream providers ──────────────────────────────────────────────────────────

/// Todos os splits cadastrados
final splitsProvider = StreamProvider<List<WorkoutSplit>>(
  (ref) => ref.watch(workoutDaoProvider).watchSplits(),
);

/// Divisão atualmente ativa (null se nenhuma)
final activeSplitProvider = StreamProvider<WorkoutSplit?>((ref) {
  return ref.watch(workoutDaoProvider).watchSplits().map((splits) {
    try {
      return splits.firstWhere((s) => s.ativo);
    } catch (_) {
      return null;
    }
  });
});

/// Dias da divisão ativa, em ordem de letra
final activeSplitDaysProvider = StreamProvider<List<WorkoutDay>>((ref) {
  final splitAsync = ref.watch(activeSplitProvider);
  return splitAsync.when(
    data: (split) {
      if (split == null) return Stream.value([]);
      return ref.watch(workoutDaoProvider).watchDaysForSplit(split.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Sessões recentes (stream)
final recentSessionsProvider = StreamProvider<List<WorkoutSession>>(
  (ref) => ref.watch(workoutDaoProvider).watchRecentSessions(),
);

/// Todas as sessões concluídas (stream)
final completedSessionsProvider = StreamProvider<List<WorkoutSession>>(
  (ref) => ref.watch(workoutDaoProvider).watchCompletedSessions(),
);


/// Sessão em andamento (null se não há nenhuma)
final activeSessionProvider = StreamProvider<WorkoutSession?>(
  (ref) => ref.watch(workoutDaoProvider).watchActiveSession(),
);

/// Perfil do usuário
final profileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(profileDaoProvider).watchProfile(),
);

/// Histórico de pesos semanais
final weeklyWeightsProvider = StreamProvider<List<WeeklyWeight>>(
  (ref) => ref.watch(profileDaoProvider).watchWeeklyWeights(),
);

/// Histórico de medidas corporais
final bodyMeasurementsProvider = StreamProvider<List<BodyMeasurement>>(
  (ref) => ref.watch(profileDaoProvider).watchAllMeasurements(),
);

/// Planejamento semanal
final weeklyScheduleProvider = StreamProvider<List<WeeklySchedule>>(
  (ref) => ref.watch(workoutDaoProvider).watchWeeklySchedule(),
);

// ── Derived / Future providers ─────────────────────────────────────────────────

/// true  → peso da semana já registrado
/// false → banner de lembrete deve aparecer
final weeklyWeightRegisteredProvider = FutureProvider<bool>((ref) async {
  // Depende do stream para re-executar quando um peso for salvo
  ref.watch(weeklyWeightsProvider);
  final dao = ref.read(profileDaoProvider);
  final weight = await dao.getWeightForWeek(WeekUtils.currentWeekKey());
  return weight != null;
});

/// Todos os exercícios ordenados por grupo muscular
final allExercisesProvider = StreamProvider<List<Exercise>>(
  (ref) => ref.watch(exerciseDaoProvider).watchAll(),
);

enum ProgressGrouping {
  byDay,
  byMuscle,
}

final progressGroupingProvider = StateProvider<ProgressGrouping>((ref) => ProgressGrouping.byDay);

class ProgressReportData {
  final List<Exercise> allTrainedExercises;
  final Map<String, List<Exercise>> groupedByMuscle;
  final Map<WorkoutDay, List<Exercise>> groupedByDay;
  final List<Exercise> exercisesWithoutDay;

  ProgressReportData({
    required this.allTrainedExercises,
    required this.groupedByMuscle,
    required this.groupedByDay,
    required this.exercisesWithoutDay,
  });
}

final progressReportProvider = FutureProvider<ProgressReportData>((ref) async {
  final allExercisesAsync = ref.watch(allExercisesProvider);
  final allExercises = allExercisesAsync.value ?? [];
  final trained = allExercises.where((e) => e.vezesFeito > 0).toList();

  // 1. Agrupar por grupo muscular
  final Map<String, List<Exercise>> groupedByMuscle = {};
  for (final ex in trained) {
    groupedByMuscle.putIfAbsent(ex.grupoMuscular, () => []).add(ex);
  }

  // 2. Agrupar por dia da divisão ativa
  final activeDaysAsync = ref.watch(activeSplitDaysProvider);
  final activeDays = activeDaysAsync.value ?? [];

  final Map<WorkoutDay, List<Exercise>> groupedByDay = {};
  final Set<int> exerciseIdsInActiveDays = {};

  final exerciseDao = ref.read(exerciseDaoProvider);
  for (final day in activeDays) {
    final dayExercises = await exerciseDao.getExercisesForDay(day.id);
    final trainedDayExercises = dayExercises.where((e) => e.vezesFeito > 0).toList();
    if (trainedDayExercises.isNotEmpty) {
      groupedByDay[day] = trainedDayExercises;
      for (final ex in trainedDayExercises) {
        exerciseIdsInActiveDays.add(ex.id);
      }
    }
  }

  // Exercícios treinados que não estão em nenhum dia da divisão ativa
  final exercisesWithoutDay = trained
      .where((ex) => !exerciseIdsInActiveDays.contains(ex.id))
      .toList();

  return ProgressReportData(
    allTrainedExercises: trained,
    groupedByMuscle: groupedByMuscle,
    groupedByDay: groupedByDay,
    exercisesWithoutDay: exercisesWithoutDay,
  );
});

class MonthSessions {
  final String monthKey;
  final DateTime monthDate;
  final List<WorkoutSession> sessions;

  MonthSessions({
    required this.monthKey,
    required this.monthDate,
    required this.sessions,
  });
}

final monthlySessionsProvider = Provider<AsyncValue<List<MonthSessions>>>((ref) {
  final sessionsAsync = ref.watch(completedSessionsProvider);
  return sessionsAsync.when(
    data: (sessions) {
      final Map<String, List<WorkoutSession>> grouped = {};
      for (final session in sessions) {
        try {
          final date = DateTime.parse(session.data);
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(key, () => []).add(session);
        } catch (_) {}
      }

      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      final List<MonthSessions> result = [];
      for (final key in sortedKeys) {
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        result.add(MonthSessions(
          monthKey: key,
          monthDate: DateTime(year, month, 1),
          sessions: grouped[key]!,
        ));
      }
      return AsyncValue.data(result);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final workoutDaysMapProvider = StreamProvider<Map<int, WorkoutDay>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.workoutDays).watch().map((days) {
    return {for (final d in days) d.id: d};
  });
});

final profilePhotoProvider = StateNotifierProvider<ProfilePhotoNotifier, String?>((ref) {
  return ProfilePhotoNotifier();
});

class ProfilePhotoNotifier extends StateNotifier<String?> {
  ProfilePhotoNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('profile_photo');
  }

  Future<void> setPhoto(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('profile_photo');
    } else {
      await prefs.setString('profile_photo', path);
    }
    state = path;
  }
}

// ── Theme Mode ────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('theme_mode');
    if (val != null) {
      if (val == 'light') {
        state = ThemeMode.light;
      } else if (val == 'system') {
        state = ThemeMode.system;
      } else {
        state = ThemeMode.dark;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final String val;
    switch (mode) {
      case ThemeMode.light:
        val = 'light';
        break;
      case ThemeMode.system:
        val = 'system';
        break;
      case ThemeMode.dark:
        val = 'dark';
        break;
    }
    await prefs.setString('theme_mode', val);
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final foregroundSessionControllerProvider = Provider<void>((ref) {
  final activeSessionAsync = ref.watch(activeSessionProvider);
  final daysMapAsync = ref.watch(workoutDaysMapProvider);

  activeSessionAsync.whenData((session) {
    if (session == null) {
      ForegroundTaskService.stop();
    } else {
      final daysMap = daysMapAsync.value;
      final dayName = daysMap?[session.dayId]?.nome ?? 'Treino';
      ForegroundTaskService.start(
        '🏋️ Mete Marcha',
        'Treino ativo: $dayName',
      );
    }
  });
});

class TodayWorkoutData {
  final String title;
  final String name;
  final String status;
  final bool hasWorkout;

  TodayWorkoutData({
    required this.title,
    required this.name,
    required this.status,
    required this.hasWorkout,
  });
}

final todayWorkoutProvider = Provider<AsyncValue<TodayWorkoutData>>((ref) {
  final scheduleAsync = ref.watch(weeklyScheduleProvider);
  final daysAsync = ref.watch(activeSplitDaysProvider);
  final activeSplitAsync = ref.watch(activeSplitProvider);

  return activeSplitAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (activeSplit) {
      if (activeSplit == null) {
        return AsyncValue.data(TodayWorkoutData(
          title: 'Mete Marcha',
          name: 'Nenhuma rotina ativa',
          status: 'Crie uma rotina',
          hasWorkout: false,
        ));
      }

      return daysAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (workoutDays) {
          return scheduleAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (e, st) => AsyncValue.error(e, st),
            data: (schedules) {
              if (schedules.isEmpty) {
                return AsyncValue.data(TodayWorkoutData(
                  title: 'Treino do Dia',
                  name: 'Nenhum agendado',
                  status: 'Configurar agenda',
                  hasWorkout: false,
                ));
              }

              final weekdayInt = DateTime.now().weekday;
              final diasSemana = [
                'Segunda-feira',
                'Terça-feira',
                'Quarta-feira',
                'Quinta-feira',
                'Sexta-feira',
                'Sábado',
                'Domingo',
              ];
              final diaSemanaHoje = diasSemana[weekdayInt - 1];

              final todaySchedule = schedules.firstWhere(
                (s) => s.diaSemana == diaSemanaHoje,
                orElse: () => schedules.first,
              );

              final assignedDay = workoutDays.firstWhere(
                (d) => d.id == todaySchedule.dayId,
                orElse: () => const WorkoutDay(id: -1, splitId: -1, letra: '', nome: ''),
              );

              final hasWorkout = assignedDay.id != -1;
              if (hasWorkout) {
                return AsyncValue.data(TodayWorkoutData(
                  title: 'Treino de Hoje',
                  name: 'Treino ${assignedDay.letra}: ${assignedDay.nome}',
                  status: 'Mete Marcha! 💪',
                  hasWorkout: true,
                ));
              } else {
                return AsyncValue.data(TodayWorkoutData(
                  title: 'Recuperação',
                  name: 'Dia de Descanso 😴',
                  status: 'Beber água! 💧',
                  hasWorkout: false,
                ));
              }
            },
          );
        },
      );
    },
  );
});

final widgetSyncControllerProvider = Provider<void>((ref) {
  // Sync Streak (Ofensiva)
  // Como streakProvider pode não estar disponível de imediato ou lançar erro se os dados não carregarem,
  // nós apenas escutamos ou lemos de forma segura.
  try {
    final streak = ref.watch(streakProvider);
    ref.listen<int>(streakProvider, (previous, next) {
      WidgetSyncService.syncStreak(next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetSyncService.syncStreak(streak);
    });
  } catch (_) {}

  // Sync Workout of the Day (Treino do Dia)
  final todayWorkoutAsync = ref.watch(todayWorkoutProvider);
  todayWorkoutAsync.whenData((data) {
    WidgetSyncService.syncWorkout(data);
  });
});

final homeTabProvider = StateProvider<int>((ref) => 0);

