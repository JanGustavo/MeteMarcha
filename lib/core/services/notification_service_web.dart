import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../pages/workout/workout_page.dart';
import '../providers/rest_timer_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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

  /// Solicita permissão para exibir notificações no navegador
  static void requestPermission() {
    try {
      web.Notification.requestPermission();
    } catch (_) {}
  }

  /// Exibe uma notificação nativa do navegador
  static void showNotification(String title, String body) {
    try {
      final permission = web.Notification.permission;
      if (permission == 'granted') {
        web.Notification(title, web.NotificationOptions(body: body));
      } else if (permission == 'default') {
        requestPermission();
      }
    } catch (_) {}
  }

  Future<void> init() async {
    requestPermission();
  }

  Future<void> showRestTimer(int secondsLeft) async {
    // No-op on web
  }

  Future<void> showRestEnded() async {
    showNotification('Descanso Concluído! 🔥', 'Hora de meter marcha na próxima série!');
  }

  Future<void> scheduleRestEndedNotification(int secondsDelay) async {
    // No-op on web
  }

  Future<void> cancelNotification() async {
    // No-op on web
  }

  Future<void> showMusicNotification(String channelName, bool isPlaying) async {
    // No-op on web
  }

  Future<void> cancelMusicNotification() async {
    // No-op on web
  }
}
