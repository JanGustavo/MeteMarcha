import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WorkoutRestBanner extends StatelessWidget {
  final int left;
  final int total;
  final VoidCallback onSkip;
  final Function(int) onAdjust;

  const WorkoutRestBanner({
    super.key,
    required this.left,
    required this.total,
    required this.onSkip,
    required this.onAdjust,
  });

  Widget _buildAdjustButton(BuildContext context, String label, int seconds) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 28,
      child: OutlinedButton(
        onPressed: () => onAdjust(seconds),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? left / total : 0.0;
    final m = (left ~/ 60).toString().padLeft(2, '0');
    final s = (left % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: context.divider,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                    Text(
                      '$m:$s',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESCANSO',
                    style: TextStyle(
                      color: context.onSurface,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Próxima série quando pronto',
                    style: TextStyle(color: context.onSurface, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(onPressed: onSkip, child: const Text('Pular')),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: context.onSurface,
                  size: 20,
                ),
                onPressed: onSkip,
                tooltip: 'Fechar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAdjustButton(context, '-30s', -30),
                _buildAdjustButton(context, '-15s', -15),
                _buildAdjustButton(context, '+15s', 15),
                _buildAdjustButton(context, '+30s', 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
