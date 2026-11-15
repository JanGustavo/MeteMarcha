import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/workout/models/workout_set_entry.dart';

class WorkoutSetsList extends StatelessWidget {
  final List<WorkoutSetEntry> sets;
  final Exercise exercise;
  final Function(int) onTapSeries;
  const WorkoutSetsList({
    super.key,
    required this.sets,
    required this.exercise,
    required this.onTapSeries,
  });

  @override
  Widget build(BuildContext context) {
    // Group sets by serie number, preserving insertion order
    final Map<int, List<WorkoutSetEntry>> grouped = {};
    for (final s in sets) {
      grouped.putIfAbsent(s.serie, () => []).add(s);
    }

    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(red: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SÉRIES SALVAS',
            style: TextStyle(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grouped.values.map((group) {
              final formattedText = _formatSeriesGroup(group);
              final serieNum = group.first.serie;
              return InkWell(
                onTap: () => onTapSeries(serieNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedText,
                        style: TextStyle(
                          color: context.onBackground,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color:
                            (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary)
                                .withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatSeriesGroup(List<WorkoutSetEntry> entries) {
    if (entries.isEmpty) return '';
    final s = entries.first;
    final serieLabel = 'S${s.serie}:';

    // Equipment and observations usually match, let's grab them from first or combine
    final eqStr =
        (s.equipamento != null && s.equipamento != exercise.equipamento)
        ? ' [${s.equipamento}]'
        : '';
    final obsStr = (s.observacoes != null && s.observacoes!.isNotEmpty)
        ? ' (${s.observacoes})'
        : '';
    final rpeStr = (s.rpe != null)
        ? ' @RPE ${s.rpe! % 1 == 0 ? s.rpe!.toInt() : s.rpe}'
        : '';

    if (entries.length == 1) {
      final ladoStr = (s.lado != 'ambos')
          ? ' (${s.lado == 'esquerdo'
                ? 'E'
                : s.lado == 'direito'
                ? 'D'
                : s.lado})'
          : '';
      return '$serieLabel ${s.peso}kg × ${s.reps}$ladoStr$rpeStr$eqStr$obsStr';
    }

    // Check if all entries in this series have the same weight
    final allSameWeight = entries.every((e) => e.peso == s.peso);
    if (allSameWeight) {
      final allSameReps = entries.every((e) => e.reps == s.reps);
      if (allSameReps) {
        // S1: 10kg × 10 (E+D)
        return '$serieLabel ${s.peso}kg × ${s.reps} (E+D)$rpeStr$eqStr$obsStr';
      } else {
        // S1: 10kg × 10(E) / 8(D)
        final repsMap = entries
            .map((e) {
              final sideLetter = e.lado == 'esquerdo'
                  ? 'E'
                  : e.lado == 'direito'
                  ? 'D'
                  : e.lado;
              return '${e.reps}($sideLetter)';
            })
            .join(' / ');
        return '$serieLabel ${s.peso}kg × $repsMap$rpeStr$eqStr$obsStr';
      }
    } else {
      // S1: 10kg × 10(E) / 12kg × 8(D)
      final parts = entries
          .map((e) {
            final sideLetter = e.lado == 'esquerdo'
                ? 'E'
                : e.lado == 'direito'
                ? 'D'
                : e.lado;
            return '${e.peso}kg × ${e.reps}($sideLetter)';
          })
          .join(' / ');
      return '$serieLabel $parts$rpeStr$eqStr$obsStr';
    }
  }
}
