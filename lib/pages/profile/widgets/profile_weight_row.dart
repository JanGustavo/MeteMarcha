import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/week_utils.dart';

class ProfileWeightRow extends StatelessWidget {
  final WeeklyWeight weight;
  final bool isCurrentWeek;
  const ProfileWeightRow({
    super.key,
    required this.weight,
    required this.isCurrentWeek,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentWeek
              ? AppColors.primary.withValues(alpha: 0.4)
              : context.divider,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.monitor_weight_rounded,
          color: isCurrentWeek ? AppColors.primary : context.onSurface,
          size: 22,
        ),
        title: Text(
          '${weight.peso.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontWeight: isCurrentWeek ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        subtitle: Text(WeekUtils.formatDateWithWeekday(weight.data)),
        trailing: Text(
          WeekUtils.formatWeekKey(weight.semana),
          style: TextStyle(color: context.onSurface, fontSize: 12),
        ),
      ),
    );
  }
}
