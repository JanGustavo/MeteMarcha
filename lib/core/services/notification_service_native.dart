// lib/core/services/notification_service_native.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'music_pause' || response.actionId == 'music_play') {
          globalProviderContainer.read(workoutMusicProvider.notifier).togglePlay();
        } else if (response.actionId == 'music_stop') {
          globalProviderContainer.read(workoutMusicProvider.notifier).stop();
        } else {
          openActiveWorkout();
        }
      },
    );

    requestPermission();
  }

  Future<void> showRestTimer(int secondsLeft) async {
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_channel',
      'Cronômetro de Descanso',
      channelDescription: 'Mostra o tempo restante de descanso',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showWhen: false,
      ongoing: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: 'MeteMacha 🏋️',
      body: 'Descanso ativo: $timeStr restante',
      notificationDetails: platformDetails,
    );
  }

  Future<void> showRestEnded() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_timer_channel',
      'Cronômetro de Descanso',
      channelDescription: 'Mostra o tempo restante de descanso',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: 'Descanso Concluído! 🔥',
      body: 'Hora de meter marcha na próxima série!',
      notificationDetails: platformDetails,
    );
  }

  Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(id: 999);
  }

  Future<void> showMusicNotification(String channelName, bool isPlaying) async {
    final List<AndroidNotificationAction> actions = [];
    if (isPlaying) {
      actions.add(const AndroidNotificationAction(
        'music_pause',
        'Pausar',
        showsUserInterface: true,
      ));
    } else {
      actions.add(const AndroidNotificationAction(
        'music_play',
        'Tocar',
        showsUserInterface: true,
      ));
    }
    actions.add(const AndroidNotificationAction(
      'music_stop',
      'Parar',
      showsUserInterface: true,
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
      title: 'MeteMacha Rádio ⚡',
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
