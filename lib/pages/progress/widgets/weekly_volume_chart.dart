import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WeeklyVolumeChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const WeeklyVolumeChart({
    super.key,
    required this.logs,
    required this.exercises,
  });

  DateTime _startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, double> weeklyVolumes = {};
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);

    // Calcula dinamicamente quantas semanas exibir com base no log mais antigo
    final oldestWeekStart = logs.isEmpty
        ? currentWeekStart
        : _startOfWeek(DateTime.tryParse(logs.first.data) ?? now);

    int weeksToGoBack = now.difference(oldestWeekStart).inDays ~/ 7;
    if (weeksToGoBack < 1) {
      weeksToGoBack = 1; // Exibe pelo menos 2 semanas (atual e anterior) para desenhar a linha
    }
    if (weeksToGoBack > 5) {
      weeksToGoBack = 5; // Limita a no máximo 6 semanas de histórico no gráfico
    }

    for (int i = weeksToGoBack; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
      weeklyVolumes[weekStart] = 0.0;
    }

    final exerciseMap = {for (final e in exercises) e.id: e};

    for (final log in logs) {
      final logDate = DateTime.tryParse(log.data);
      if (logDate == null) continue;
      final weekStart = _startOfWeek(logDate);
      if (weeklyVolumes.containsKey(weekStart)) {
        final ex = exerciseMap[log.exerciseId];
        final isUnilateral = ex?.isUnilateral ?? false;
        final vol = LogDao.calcularVolume(log, isUnilateral: isUnilateral);
        weeklyVolumes[weekStart] = (weeklyVolumes[weekStart] ?? 0.0) + vol;
      }
    }

    final sortedWeeks = weeklyVolumes.keys.toList()..sort();
    final spots = sortedWeeks.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), weeklyVolumes[e.value] ?? 0.0);
    }).toList();

    final maxVal = weeklyVolumes.values.isEmpty
        ? 1000.0
        : weeklyVolumes.values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    if (weeklyVolumes.values.every((v) => v == 0.0)) {
      return SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Nenhum volume de treino registrado nas últimas semanas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => context.surfaceColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= sortedWeeks.length) return null;
                  final weekStart = sortedWeeks[idx];
                  final vol = weeklyVolumes[weekStart] ?? 0.0;
                  final text =
                      '${dateToFormat(weekStart)}: ${vol.toStringAsFixed(0)} kg';
                  return LineTooltipItem(
                    text,
                    TextStyle(
                      color: context.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  if (v != v.toInt().toDouble()) return const SizedBox();
                  final idx = v.toInt();
                  if (idx < 0 || idx >= sortedWeeks.length)
                    return const SizedBox();
                  final date = sortedWeeks[idx];
                  final text = '${date.day}/${date.month}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      text,
                      style: TextStyle(color: context.onSurface, fontSize: 8),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v >= 1000
                      ? '${(v / 1000).toStringAsFixed(1)}k'
                      : v.toStringAsFixed(0),
                  style: TextStyle(color: context.onSurface, fontSize: 9),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String dateToFormat(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
