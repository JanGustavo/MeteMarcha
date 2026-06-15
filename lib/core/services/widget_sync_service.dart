import 'package:home_widget/home_widget.dart';
import '../providers/providers.dart';

class WidgetSyncService {
  static Future<void> syncStreak(int count) async {
    await HomeWidget.saveWidgetData<int>('streak_count', count);
    await HomeWidget.updateWidget(
      name: 'StreakWidgetProvider',
      androidName: 'StreakWidgetProvider',
    );
  }

  static Future<void> syncWorkout(TodayWorkoutData data) async {
    await HomeWidget.saveWidgetData<String>('workout_title', data.title);
    await HomeWidget.saveWidgetData<String>('workout_name', data.name);
    await HomeWidget.saveWidgetData<String>('workout_status', data.status);
    await HomeWidget.updateWidget(
      name: 'WorkoutWidgetProvider',
      androidName: 'WorkoutWidgetProvider',
    );
  }
}
