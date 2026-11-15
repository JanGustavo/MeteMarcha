import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class MetricSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositiveChange;
  final IconData icon;
  final Color color;

  const MetricSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.isPositiveChange,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? color.withValues(alpha: 0.05)
        : color.withValues(alpha: 0.08);
    final borderColor = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? context.onSurface
                        : AppColors.lightOnSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? context.onBackground
                  : AppColors.lightOnBackground,
            ),
          ),
          const SizedBox(height: 4),
          if (change.isNotEmpty)
            Row(
              children: [
                Icon(
                  isPositiveChange
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: isPositiveChange
                      ? AppColors.success
                      : AppColors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPositiveChange
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Sem histórico',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

// ── Evolution Chart ──────────────────────────────────────────────────────────
