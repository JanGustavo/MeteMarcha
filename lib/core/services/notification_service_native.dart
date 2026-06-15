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
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final boldTime = _toUnicodeBold(timeStr);

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
      actions: actions,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: '⏱️ $boldTime',
      body: 'Descanso ativo • Mete Marcha 🏋️',
      notificationDetails: platformDetails,
    );
  }

  String _toUnicodeBold(String input) {
    final Map<String, String> boldMap = {
      '0': '𝟎', '1': '𝟏', '2': '𝟐', '3': '𝟑', '4': '𝟒',
      '5': '𝟓', '6': '𝟔', '7': '𝟕', '8': '𝟖', '9': '𝟗',
    };
    return input.split('').map((char) => boldMap[char] ?? char).join();
  }

  Future<void> scheduleRestEndedNotification(int secondsDelay) async {
    // Cancela qualquer alarme agendado anteriormente com esse id
    await _notificationsPlugin.cancel(id: 998);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsDelay));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_ended_channel',
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

    await _notificationsPlugin.zonedSchedule(
      id: 998,
      title: 'Descanso Concluído! 🔥',
      body: 'Hora de meter marcha na próxima série!',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showRestEnded() async {
    await _notificationsPlugin.cancel(id: 999); // Limpa o cronômetro ativo

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_ended_channel',
      'Fim do Descanso (Alerta)',
      channelDescription: 'Dispara um alerta sonoro e visual ao fim do descanso',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
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
