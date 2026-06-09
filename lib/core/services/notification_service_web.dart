// lib/core/services/notification_service_web.dart

import 'dart:js' as js;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Solicita permissão para exibir notificações no navegador
  static void requestPermission() {
    try {
      if (js.context.hasProperty('Notification')) {
        final notification = js.context['Notification'];
        notification.callMethod('requestPermission');
      }
    } catch (_) {}
  }

  /// Exibe uma notificação nativa do navegador
  static void showNotification(String title, String body) {
    try {
      if (js.context.hasProperty('Notification')) {
        final notificationClass = js.context['Notification'];
        final permission = notificationClass['permission'];
        if (permission == 'granted') {
          js.JsObject(notificationClass, [
            title,
            js.JsObject.jsify({'body': body}),
          ]);
        } else if (permission == 'default') {
          requestPermission();
        }
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
