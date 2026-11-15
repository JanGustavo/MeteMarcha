import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/providers/alerts_provider.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WorkoutInsightsCard extends ConsumerWidget {
  const WorkoutInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawInsights = ref.watch(automaticInsightsProvider);
    final fatigue = ref.watch(fatigueInsightProvider);

    final List<WorkoutInsight> insights = List<WorkoutInsight>.from(
      rawInsights,
    );

    if (fatigue.status != 'Sem Dados') {
      IconData icon;
      Color color;
      String type;
      if (fatigue.status == 'Crítico') {
        icon = Icons.warning_amber_rounded;
        color = Colors.redAccent;
        type = 'warning';
      } else if (fatigue.status == 'Atenção') {
        icon = Icons.info_outline;
        color = Colors.orangeAccent;
        type = 'warning';
      } else if (fatigue.status == 'Ideal') {
        icon = Icons.check_circle_outline;
        color = Colors.greenAccent;
        type = 'positive';
      } else {
        icon = Icons.trending_up_rounded;
        color = Colors.blueAccent;
        type = 'neutral';
      }

      insights.insert(
        0,
        WorkoutInsight(
          text:
              'Fadiga: ${fatigue.status}. Esforço médio (RPE) em ${fatigue.averageRpe.toStringAsFixed(1)}. ${fatigue.warnings.isNotEmpty ? "Alertas: ${fatigue.warnings.join(", ")}" : fatigue.message}',
          icon: icon,
          color: color,
          type: type,
        ),
      );
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryLight,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'INSIGHTS DA SEMANA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: insight.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: insight.color.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(insight.icon, color: insight.color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.onBackground.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Painel de Fadiga e Recuperação ──────────────────────────────────────────
