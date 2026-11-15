import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WorkoutInfoChip extends StatelessWidget {
  final String label;
  const WorkoutInfoChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.divider),
      ),
      child: Text(
        label,
        style: TextStyle(color: context.onSurface, fontSize: 11),
      ),
    );
  }
}
