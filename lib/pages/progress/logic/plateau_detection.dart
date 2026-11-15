import 'package:gym_tracker/core/database/app_database.dart';

class PlateauInfo {
  final Exercise exercise;
  final double currentMax1RM;
  final double previousMax1RM;
  final double previous2Max1RM;
  final double lastSessionMaxWeight;
  final double suggestedDeloadWeight;

  PlateauInfo({
    required this.exercise,
    required this.currentMax1RM,
    required this.previousMax1RM,
    required this.previous2Max1RM,
    required this.lastSessionMaxWeight,
    required this.suggestedDeloadWeight,
  });
}

List<PlateauInfo> detectPlateaus(
  List<ExerciseLog> logs,
  List<Exercise> exercises,
) {
  final List<PlateauInfo> plateaus = [];

  final Map<int, List<ExerciseLog>> logsByExercise = {};
  for (final log in logs) {
    logsByExercise.putIfAbsent(log.exerciseId, () => []).add(log);
  }

  for (final exercise in exercises) {
    final exerciseLogs = logsByExercise[exercise.id];
    if (exerciseLogs == null || exerciseLogs.isEmpty) continue;

    final List<int> sessionIds = [];
    final Map<int, List<ExerciseLog>> logsBySession = {};
    for (final log in exerciseLogs) {
      if (!logsBySession.containsKey(log.sessionId)) {
        sessionIds.add(log.sessionId);
        logsBySession[log.sessionId] = [];
      }
      logsBySession[log.sessionId]!.add(log);
    }

    if (sessionIds.length >= 3) {
      final sN_2 = sessionIds[sessionIds.length - 3];
      final sN_1 = sessionIds[sessionIds.length - 2];
      final sN = sessionIds[sessionIds.length - 1];

      double getMax1RM(List<ExerciseLog> sessionLogs) {
        double maxVal = 0.0;
        for (final l in sessionLogs) {
          final oneRM = l.repeticoes == 1
              ? l.peso
              : l.peso * (1 + l.repeticoes / 30.0);
          if (oneRM > maxVal) {
            maxVal = oneRM;
          }
        }
        return maxVal;
      }

      final oneRMN_2 = getMax1RM(logsBySession[sN_2]!);
      final oneRMN_1 = getMax1RM(logsBySession[sN_1]!);
      final oneRMN = getMax1RM(logsBySession[sN]!);

      if (oneRMN <= oneRMN_1 && oneRMN_1 <= oneRMN_2) {
        double maxWeight = 0.0;
        for (final l in logsBySession[sN]!) {
          if (l.peso > maxWeight) {
            maxWeight = l.peso;
          }
        }

        plateaus.add(
          PlateauInfo(
            exercise: exercise,
            currentMax1RM: oneRMN,
            previousMax1RM: oneRMN_1,
            previous2Max1RM: oneRMN_2,
            lastSessionMaxWeight: maxWeight,
            suggestedDeloadWeight: maxWeight * 0.9,
          ),
        );
      }
    }
  }

  return plateaus;
}
