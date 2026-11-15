import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WorkoutPreviousPerformance extends StatelessWidget {
  final List<ExerciseLog> logs;
  final Exercise exercise;
  const WorkoutPreviousPerformance({
    super.key,
    required this.logs,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    double prevSessionMax1RM = 0.0;
    for (final l in logs) {
      final oneRM = l.repeticoes == 1
          ? l.peso
          : l.peso * (1 + l.repeticoes / 30.0);
      if (oneRM > prevSessionMax1RM) {
        prevSessionMax1RM = oneRM;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÚLTIMO TREINO',
                style: TextStyle(
                  color: context.onSurface,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (prevSessionMax1RM > 0)
                Text(
                  'Max 1RM: ${prevSessionMax1RM.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: logs.map((l) {
              final ladoStr = (l.lado != 'ambos') ? ' (${l.lado})' : '';
              final eqStr =
                  (l.equipamento != null &&
                      l.equipamento != exercise.equipamento)
                  ? ' [${l.equipamento}]'
                  : '';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'S${l.serie}: ${l.peso}kg × ${l.repeticoes}$ladoStr$eqStr',
                  style: TextStyle(
                    color: context.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
