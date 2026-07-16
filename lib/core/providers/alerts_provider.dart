// lib/core/providers/alerts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'providers.dart';

// ── Membership Alert ──────────────────────────────────────────────────────────

class MembershipState {
  final bool enabled;
  final double value;
  final int months; // 1 = mensal, 12 = anual, ou custom
  final DateTime nextDueDate;
  final bool alertOnDay;
  final bool alert3Days;
  final bool alert1Week;

  MembershipState({
    required this.enabled,
    required this.value,
    required this.months,
    required this.nextDueDate,
    required this.alertOnDay,
    required this.alert3Days,
    required this.alert1Week,
  });

  MembershipState copyWith({
    bool? enabled,
    double? value,
    int? months,
    DateTime? nextDueDate,
    bool? alertOnDay,
    bool? alert3Days,
    bool? alert1Week,
  }) {
    return MembershipState(
      enabled: enabled ?? this.enabled,
      value: value ?? this.value,
      months: months ?? this.months,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      alertOnDay: alertOnDay ?? this.alertOnDay,
      alert3Days: alert3Days ?? this.alert3Days,
      alert1Week: alert1Week ?? this.alert1Week,
    );
  }
}

final membershipToastTriggeredProvider = StateProvider<bool>((ref) => false);
final membershipWarningSnoozedProvider = StateProvider<bool>((ref) => false);

class MembershipNotifier extends StateNotifier<MembershipState> {
  final Ref _ref;

  MembershipNotifier(this._ref)
      : super(MembershipState(
          enabled: false,
          value: 0.0,
          months: 1,
          nextDueDate: DateTime.now().add(const Duration(days: 30)),
          alertOnDay: true,
          alert3Days: false,
          alert1Week: false,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('membership_enabled') ?? false;
    final value = prefs.getDouble('membership_value') ?? 0.0;
    final months = prefs.getInt('membership_months') ?? 1;
    final nextDueDateStr = prefs.getString('membership_next_due_date');
    final nextDueDate = nextDueDateStr != null
        ? DateTime.tryParse(nextDueDateStr) ?? DateTime.now().add(Duration(days: months * 30))
        : DateTime.now().add(Duration(days: months * 30));
    final alertOnDay = prefs.getBool('membership_alert_on_day') ?? true;
    final alert3Days = prefs.getBool('membership_alert_3_days') ?? false;
    final alert1Week = prefs.getBool('membership_alert_1_week') ?? false;

    state = MembershipState(
      enabled: enabled,
      value: value,
      months: months,
      nextDueDate: nextDueDate,
      alertOnDay: alertOnDay,
      alert3Days: alert3Days,
      alert1Week: alert1Week,
    );
  }

  Future<void> updateSettings({
    bool? enabled,
    double? value,
    int? months,
    DateTime? nextDueDate,
    bool? alertOnDay,
    bool? alert3Days,
    bool? alert1Week,
  }) async {
    // Reset transient UI warning states upon settings changes
    _ref.read(membershipToastTriggeredProvider.notifier).state = false;
    _ref.read(membershipWarningSnoozedProvider.notifier).state = false;

    final newState = state.copyWith(
      enabled: enabled,
      value: value,
      months: months,
      nextDueDate: nextDueDate,
      alertOnDay: alertOnDay,
      alert3Days: alert3Days,
      alert1Week: alert1Week,
    );

    state = newState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('membership_enabled', newState.enabled);
    await prefs.setDouble('membership_value', newState.value);
    await prefs.setInt('membership_months', newState.months);
    await prefs.setString('membership_next_due_date', newState.nextDueDate.toIso8601String());
    await prefs.setBool('membership_alert_on_day', newState.alertOnDay);
    await prefs.setBool('membership_alert_3_days', newState.alert3Days);
    await prefs.setBool('membership_alert_1_week', newState.alert1Week);

    if (newState.enabled) {
      await NotificationService().scheduleMembershipNotifications(
        value: newState.value,
        months: newState.months,
        nextDueDate: newState.nextDueDate,
        alertOnDay: newState.alertOnDay,
        alert3Days: newState.alert3Days,
        alert1Week: newState.alert1Week,
      );
    } else {
      await NotificationService().cancelMembershipNotifications();
    }
  }

  Future<void> markAsPaid() async {
    final current = state.nextDueDate;
    int newYear = current.year;
    int newMonth = current.month + state.months;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    
    int newDay = current.day;
    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > lastDayOfNewMonth) {
      newDay = lastDayOfNewMonth;
    }

    final newDueDate = DateTime(newYear, newMonth, newDay);
    await updateSettings(nextDueDate: newDueDate);
  }
}

final membershipSettingsProvider =
    StateNotifierProvider<MembershipNotifier, MembershipState>((ref) {
  return MembershipNotifier(ref);
});

class MembershipMetrics {
  final DateTime cycleStartDate;
  final DateTime cycleEndDate;
  final int workoutCount;
  final double totalDurationHours;
  final int cardioCount;
  final double totalCardioDurationHours;
  final double costPerWorkout;
  final double costPerCardio;
  final double costPerVisit; // Treino + Cárdio
  final double costPerHour; // Horas combinadas

  MembershipMetrics({
    required this.cycleStartDate,
    required this.cycleEndDate,
    required this.workoutCount,
    required this.totalDurationHours,
    required this.cardioCount,
    required this.totalCardioDurationHours,
    required this.costPerWorkout,
    required this.costPerCardio,
    required this.costPerVisit,
    required this.costPerHour,
  });
}

DateTime calculateCycleStartDate(DateTime nextDueDate, int months) {
  int newYear = nextDueDate.year;
  int newMonth = nextDueDate.month - months;
  while (newMonth < 1) {
    newMonth += 12;
    newYear -= 1;
  }
  
  int newDay = nextDueDate.day;
  final lastDayOfPrevMonth = DateTime(newYear, newMonth + 1, 0).day;
  if (newDay > lastDayOfPrevMonth) {
    newDay = lastDayOfPrevMonth;
  }
  
  return DateTime(newYear, newMonth, newDay, 0, 0, 0);
}

final membershipMetricsProvider = Provider<MembershipMetrics?>((ref) {
  final membership = ref.watch(membershipSettingsProvider);
  if (!membership.enabled) return null;

  final sessionsAsync = ref.watch(completedSessionsProvider);
  final cardiosAsync = ref.watch(cardiosProvider);

  final sessions = sessionsAsync.value;
  final cardios = cardiosAsync.value;
  if (sessions == null || cardios == null) return null;

  final endDate = membership.nextDueDate;
  final cycleEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  final cycleStartDate = calculateCycleStartDate(endDate, membership.months);
  
  final startLimit = cycleStartDate.subtract(const Duration(seconds: 1));
  final endLimit = cycleEndDate;

  // Filtra treinos (musculação) no ciclo
  final cycleSessions = sessions.where((s) {
    final date = DateTime.tryParse(s.data);
    if (date == null) return false;
    return date.isAfter(startLimit) && date.isBefore(endLimit);
  }).toList();

  final workoutCount = cycleSessions.length;
  int workoutSeconds = 0;
  for (final s in cycleSessions) {
    workoutSeconds += s.duracaoSegundos ?? 0;
  }
  final workoutHours = workoutSeconds / 3600.0;

  // Filtra cárdios no ciclo
  final cycleCardios = cardios.where((c) {
    final date = DateTime.tryParse(c.data);
    if (date == null) return false;
    return date.isAfter(startLimit) && date.isBefore(endLimit);
  }).toList();

  final cardioCount = cycleCardios.length;
  int cardioSeconds = 0;
  for (final c in cycleCardios) {
    cardioSeconds += c.duracaoSegundos;
  }
  final cardioHours = cardioSeconds / 3600.0;

  // Cálculos combinados
  final combinedCount = workoutCount + cardioCount;
  final combinedHours = workoutHours + cardioHours;

  final costPerWorkout = workoutCount > 0 ? membership.value / workoutCount : membership.value;
  final costPerCardio = cardioCount > 0 ? membership.value / cardioCount : membership.value;
  final costPerVisit = combinedCount > 0 ? membership.value / combinedCount : membership.value;
  final costPerHour = combinedHours > 0 ? membership.value / combinedHours : membership.value;

  return MembershipMetrics(
    cycleStartDate: cycleStartDate,
    cycleEndDate: endDate,
    workoutCount: workoutCount,
    totalDurationHours: workoutHours,
    cardioCount: cardioCount,
    totalCardioDurationHours: cardioHours,
    costPerWorkout: costPerWorkout,
    costPerCardio: costPerCardio,
    costPerVisit: costPerVisit,
    costPerHour: costPerHour,
  );
});

// ── Workout Reminder ──────────────────────────────────────────────────────────

class WorkoutReminderState {
  final bool enabled;
  final String globalTime;
  final Map<String, String> customTimes; // 'Segunda-feira' -> '18:00'

  WorkoutReminderState({
    required this.enabled,
    required this.globalTime,
    required this.customTimes,
  });

  WorkoutReminderState copyWith({
    bool? enabled,
    String? globalTime,
    Map<String, String>? customTimes,
  }) {
    return WorkoutReminderState(
      enabled: enabled ?? this.enabled,
      globalTime: globalTime ?? this.globalTime,
      customTimes: customTimes ?? this.customTimes,
    );
  }
}

class WorkoutReminderNotifier extends StateNotifier<WorkoutReminderState> {
  final Ref _ref;

  WorkoutReminderNotifier(this._ref)
      : super(WorkoutReminderState(
          enabled: false,
          globalTime: '08:00',
          customTimes: {},
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('workout_reminder_enabled') ?? false;
    final globalTime = prefs.getString('workout_reminder_global_time') ?? '08:00';
    
    final Map<String, String> customTimes = {};
    final weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    for (final day in weekdays) {
      final val = prefs.getString('workout_reminder_time_$day');
      if (val != null) {
        customTimes[day] = val;
      }
    }

    state = WorkoutReminderState(
      enabled: enabled,
      globalTime: globalTime,
      customTimes: customTimes,
    );
  }

  Future<void> updateSettings({
    bool? enabled,
    String? globalTime,
    Map<String, String>? customTimes,
  }) async {
    final newState = state.copyWith(
      enabled: enabled,
      globalTime: globalTime,
      customTimes: customTimes,
    );

    state = newState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('workout_reminder_enabled', newState.enabled);
    await prefs.setString('workout_reminder_global_time', newState.globalTime);
    
    for (final entry in newState.customTimes.entries) {
      await prefs.setString('workout_reminder_time_${entry.key}', entry.value);
    }

    await reschedule();
  }

  Future<void> updateDayTime(String day, String time) async {
    final newCustom = Map<String, String>.from(state.customTimes);
    newCustom[day] = time;
    await updateSettings(customTimes: newCustom);
  }

  Future<void> removeDayTime(String day) async {
    final newCustom = Map<String, String>.from(state.customTimes);
    newCustom.remove(day);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workout_reminder_time_$day');
    
    await updateSettings(customTimes: newCustom);
  }

  Future<void> reschedule() async {
    final schedules = _ref.read(weeklyScheduleProvider).value ?? [];
    final workoutDays = _ref.read(activeSplitDaysProvider).value ?? [];
    
    await NotificationService().scheduleWorkoutReminders(
      schedules: schedules,
      workoutDays: workoutDays,
      enabled: state.enabled,
      globalTimeStr: state.globalTime,
      customTimes: state.customTimes,
    );
  }
}

final workoutReminderSettingsProvider =
    StateNotifierProvider<WorkoutReminderNotifier, WorkoutReminderState>((ref) {
  final notifier = WorkoutReminderNotifier(ref);
  
  ref.listen(weeklyScheduleProvider, (prev, next) {
    notifier.reschedule();
  });
  ref.listen(activeSplitDaysProvider, (prev, next) {
    notifier.reschedule();
  });

  return notifier;
});
