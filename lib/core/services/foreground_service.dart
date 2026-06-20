import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  static void init() {
    if (kIsWeb) return;
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'active_workout_channel',
          channelName: 'Treino Ativo',
          channelDescription: 'Mantém o treino ativo e o cronômetro funcionando em segundo plano',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          allowWakeLock: true,
        ),
      );
    } catch (_) {}
  }

  static Future<void> start(String title, String body) async {
    if (kIsWeb) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: body,
        );
        return;
      }
      await FlutterForegroundTask.startService(
        notificationTitle: title,
        notificationText: body,
        callback: startCallback,
      );
    } catch (_) {}
  }

  static Future<void> update(String title, String body) async {
    if (kIsWeb) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: body,
        );
      }
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // O objetivo principal é manter o isolate do Flutter vivo.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Sem tarefas recorrentes necessárias no background isolate.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Cleanup opcional.
  }
}
