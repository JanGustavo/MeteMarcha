// lib/core/services/notification_service_native.dart

import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../main.dart';
import '../../pages/workout/workout_page.dart';
import '../providers/rest_timer_provider.dart';
import '../providers/progress_extended_provider.dart';
import '../database/app_database.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Solicita permissão para exibir notificações
  static void requestPermission() {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Exibe uma notificação nativa padrão
  static void showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Notificações Padrão',
      channelDescription: 'Canal de notificações padrão do aplicativo',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await _notificationsPlugin.show(
      id: 888,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux,
    );

    // Registra a porta de comunicação para ações em background
    final ReceivePort port = ReceivePort();
    IsolateNameServer.removePortNameMapping('notification_action_port');
    IsolateNameServer.registerPortWithName(port.sendPort, 'notification_action_port');
    port.listen((message) {
      if (message == 'rest_add_30s') {
        globalProviderContainer.read(restTimerProvider.notifier).add30Seconds();
      } else if (message == 'rest_skip') {
        globalProviderContainer.read(restTimerProvider.notifier).cancelRest();
      } else if (message == 'music_pause' || message == 'music_play') {
        globalProviderContainer.read(workoutMusicProvider.notifier).togglePlay();
      } else if (message == 'music_stop') {
        globalProviderContainer.read(workoutMusicProvider.notifier).stop();
      }
    });

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'music_pause' || response.actionId == 'music_play') {
          globalProviderContainer.read(workoutMusicProvider.notifier).togglePlay();
        } else if (response.actionId == 'music_stop') {
          globalProviderContainer.read(workoutMusicProvider.notifier).stop();
        } else if (response.actionId == 'rest_add_30s') {
          globalProviderContainer.read(restTimerProvider.notifier).add30Seconds();
        } else if (response.actionId == 'rest_skip') {
          globalProviderContainer.read(restTimerProvider.notifier).cancelRest();
        } else {
          openActiveWorkout();
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    requestPermission();
  }

  Future<void> showRestTimer(int secondsLeft) async {
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        'rest_add_30s',
        '+30s',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        'rest_skip',
        'Pular',
        showsUserInterface: true,
      ),
    ];

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_countdown_channel',
      'Cronômetro de Descanso (Contagem)',
      channelDescription: 'Mostra o tempo restante de descanso em tempo real',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch + secondsLeft * 1000,
      usesChronometer: true,
      chronometerCountDown: true,
      ongoing: true,
      timeoutAfter: secondsLeft * 1000,
      actions: actions,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: '⏱️ Descanso Ativo',
      body: 'Mete Marcha 🏋️',
      notificationDetails: platformDetails,
    );
  }

  Future<void> scheduleRestEndedNotification(int secondsDelay) async {
    // Cancela qualquer alarme agendado anteriormente com esse id
    await _notificationsPlugin.cancel(id: 998);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsDelay));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_ended_channel_v2',
      'Fim do Descanso (Alerta)',
      channelDescription: 'Dispara um alerta sonoro e visual ao fim do descanso',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 998,
        title: 'Descanso Concluído! 🔥',
        body: 'Hora de meter marcha na próxima série!',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Erro ao agendar com alarme exato: $e. Tentando modo aproximado...');
      await _notificationsPlugin.zonedSchedule(
        id: 998,
        title: 'Descanso Concluído! 🔥',
        body: 'Hora de meter marcha na próxima série!',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> showRestEnded() async {
    await _notificationsPlugin.cancel(id: 999); // Limpa o cronômetro ativo

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_ended_channel_v2',
      'Fim do Descanso (Alerta)',
      channelDescription: 'Dispara um alerta sonoro e visual ao fim do descanso',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 998,
      title: 'Descanso Concluído! 🔥',
      body: 'Hora de meter marcha na próxima série!',
      notificationDetails: platformDetails,
    );
  }

  Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(id: 999);
    await _notificationsPlugin.cancel(id: 998);
  }

  Future<void> showMusicNotification(String channelName, bool isPlaying) async {
    final List<AndroidNotificationAction> actions = [];
    if (isPlaying) {
      actions.add(const AndroidNotificationAction(
        'music_pause',
        'Pausar',
        showsUserInterface: false,
      ));
    } else {
      actions.add(const AndroidNotificationAction(
        'music_play',
        'Tocar',
        showsUserInterface: false,
      ));
    }
    actions.add(const AndroidNotificationAction(
      'music_stop',
      'Parar',
      showsUserInterface: false,
    ));

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'music_channel',
      'Controle de Rádio de Treino',
      channelDescription: 'Permite pausar, tocar ou parar a rádio de treino',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: isPlaying,
      showWhen: false,
      onlyAlertOnce: true,
      actions: actions,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 777,
      title: 'Mete Marcha Rádio ⚡',
      body: '$channelName: ${isPlaying ? "Tocando" : "Pausado"}',
      notificationDetails: platformDetails,
    );
  }

  Future<void> cancelMusicNotification() async {
    await _notificationsPlugin.cancel(id: 777);
  }

  Future<void> scheduleMembershipNotifications({
    required double value,
    required int months,
    required DateTime nextDueDate,
    required bool alertOnDay,
    required bool alert3Days,
    required bool alert1Week,
  }) async {
    await cancelMembershipNotifications();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'membership_alert_channel',
      'Alertas de Mensalidade',
      channelDescription: 'Lembretes de pagamento da assinatura/mensalidade da academia',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    const title = 'Lembrete de Mensalidade 💳';
    final formattedValue = value.toStringAsFixed(2);
    final period = months == 1 ? 'mensal' : (months == 12 ? 'anual' : '$months meses');
    final baseMessage = 'Sua assinatura ($period) de R\$ $formattedValue vence ';

    if (alertOnDay) {
      final scheduledDate = tz.TZDateTime.from(
        DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day, 9, 0),
        tz.local,
      );
      if (scheduledDate.isAfter(DateTime.now())) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: 1001,
            title: title,
            body: '${baseMessage}hoje! Pague para evitar frustrações. 🏋️',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          await _notificationsPlugin.zonedSchedule(
            id: 1001,
            title: title,
            body: '${baseMessage}hoje! Pague para evitar frustrações. 🏋️',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }

    if (alert3Days) {
      final date = nextDueDate.subtract(const Duration(days: 3));
      final scheduledDate = tz.TZDateTime.from(
        DateTime(date.year, date.month, date.day, 9, 0),
        tz.local,
      );
      if (scheduledDate.isAfter(DateTime.now())) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: 1002,
            title: title,
            body: '${baseMessage}em 3 dias! Organize-se para o pagamento. 💰',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          await _notificationsPlugin.zonedSchedule(
            id: 1002,
            title: title,
            body: '${baseMessage}em 3 dias! Organize-se para o pagamento. 💰',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }

    if (alert1Week) {
      final date = nextDueDate.subtract(const Duration(days: 7));
      final scheduledDate = tz.TZDateTime.from(
        DateTime(date.year, date.month, date.day, 9, 0),
        tz.local,
      );
      if (scheduledDate.isAfter(DateTime.now())) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: 1003,
            title: title,
            body: '${baseMessage}em 1 semana. Evite frustrações! 🏋️‍♀️',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          await _notificationsPlugin.zonedSchedule(
            id: 1003,
            title: title,
            body: '${baseMessage}em 1 semana. Evite frustrações! 🏋️‍♀️',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }
  }

  Future<void> cancelMembershipNotifications() async {
    await _notificationsPlugin.cancel(id: 1001);
    await _notificationsPlugin.cancel(id: 1002);
    await _notificationsPlugin.cancel(id: 1003);
  }

  tz.TZDateTime _nextInstanceOfAlert(int workoutWeekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var workoutDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (workoutDate.weekday != workoutWeekday) {
      workoutDate = workoutDate.add(const Duration(days: 1));
    }
    var alertDate = workoutDate.subtract(const Duration(minutes: 30));
    if (alertDate.isBefore(now)) {
      alertDate = alertDate.add(const Duration(days: 7));
    }
    return alertDate;
  }

  int _weekdayStringToNo(String dia) {
    switch (dia.toLowerCase()) {
      case 'segunda-feira':
      case 'segunda':
        return DateTime.monday;
      case 'terça-feira':
      case 'terça':
        return DateTime.tuesday;
      case 'quarta-feira':
      case 'quarta':
        return DateTime.wednesday;
      case 'quinta-feira':
      case 'quinta':
        return DateTime.thursday;
      case 'sexta-feira':
      case 'sexta':
        return DateTime.friday;
      case 'sábado':
      case 'sabado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  Future<void> scheduleWorkoutReminders({
    required List<WeeklySchedule> schedules,
    required List<WorkoutDay> workoutDays,
    required bool enabled,
    required String globalTimeStr,
    required Map<String, String> customTimes,
  }) async {
    await cancelWorkoutReminders();

    if (!enabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'workout_reminder_channel',
      'Lembretes de Treino',
      channelDescription: 'Notificações enviadas 30 minutos antes do horário de treino agendado',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final dayNames = {for (final d in workoutDays) d.id: d.nome};

    for (final schedule in schedules) {
      if (schedule.dayId == null) continue;

      final dayName = dayNames[schedule.dayId] ?? 'Treino';
      final weekday = _weekdayStringToNo(schedule.diaSemana);

      final timeStr = customTimes[schedule.diaSemana] ?? globalTimeStr;
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      final scheduledDate = _nextInstanceOfAlert(weekday, hour, minute);
      final id = 2000 + weekday;

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: 'Hora de treinar! 🏋️',
          body: 'Seu treino "$dayName" está agendado para as $timeStr. Faltam 30 minutos!',
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Erro ao agendar lembrete com alarme exato: $e. Tentando modo aproximado...');
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: 'Hora de treinar! 🏋️',
            body: 'Seu treino "$dayName" está agendado para as $timeStr. Faltam 30 minutos!',
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> cancelWorkoutReminders() async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _notificationsPlugin.cancel(id: 2000 + weekday);
    }
  }

  static void openActiveWorkout() {
    final state = globalProviderContainer.read(restTimerProvider);
    if (state.dayId != null && state.sessionId != null) {
      if (state.inWorkoutPage) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => WorkoutPage(
            dayId: state.dayId!,
            dayName: state.dayName ?? 'Treino',
            sessionId: state.sessionId!,
          ),
        ),
      );
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == 'rest_add_30s' || response.actionId == 'rest_skip' ||
      response.actionId == 'music_pause' || response.actionId == 'music_play' || response.actionId == 'music_stop') {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('notification_action_port');
    sendPort?.send(response.actionId);
  }
}
