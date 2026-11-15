import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/providers/alerts_provider.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';

class FatigueInsightsCard extends ConsumerWidget {
  const FatigueInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fatigue = ref.watch(fatigueInsightProvider);

    Color statusColor;
    IconData statusIcon;
    switch (fatigue.status) {
      case 'Crítico':
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'Atenção':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.info_outline;
        break;
      case 'Ideal':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Estímulo Leve':
        statusColor = Colors.blueAccent;
        statusIcon = Icons.trending_up_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ProgressSectionLabel('FADIGA & RECUPERAÇÃO'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        fatigue.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fatigue.status == 'Sem Dados') ...[
              Text(
                fatigue.message,
                style: TextStyle(
                  fontSize: 13,
                  color: context.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: fatigue.averageRpe / 10.0,
                          strokeWidth: 8,
                          backgroundColor: context.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fatigue.averageRpe.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.onBackground,
                            ),
                          ),
                          Text(
                            'RPE Médio',
                            style: TextStyle(
                              fontSize: 8,
                              color: context.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricRow(
                          context,
                          'Séries Analisadas:',
                          '${fatigue.totalSetsWithRpe}',
                          Icons.fitness_center_rounded,
                        ),
                        const SizedBox(height: 6),
                        _buildMetricRow(
                          context,
                          'Taxa de Falha:',
                          '${(fatigue.failureRatio * 100).toStringAsFixed(0)}%',
                          Icons.flash_on_rounded,
                          valueColor: fatigue.failureRatio >= 0.45
                              ? Colors.redAccent
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: context.divider, height: 1),
              const SizedBox(height: 12),
              Text(
                fatigue.message,
                style: TextStyle(
                  fontSize: 13,
                  color: context.onBackground.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              if (fatigue.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Alertas de Risco:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...fatigue.warnings.map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.onBackground.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.onSurface.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? context.onBackground,
          ),
        ),
      ],
    );
  }
}

// ─── Gráfico de peso corporal ─────────────────────────────────────────────────
