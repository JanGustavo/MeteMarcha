import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class LoadEvolutionChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final int exerciseId;

  const LoadEvolutionChart({
    super.key,
    required this.logs,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context) {
    final exLogs = logs.where((l) => l.exerciseId == exerciseId).toList();
    if (exLogs.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Histórico insuficiente para este exercício.',
            style: TextStyle(color: context.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    final Map<int, double> maxWeightPerSession = {};
    final Map<int, DateTime> sessionDates = {};
    for (final log in exLogs) {
      final date = DateTime.tryParse(log.data) ?? DateTime.now();
      final currentMax = maxWeightPerSession[log.sessionId];
      if (currentMax == null || log.peso > currentMax) {
        maxWeightPerSession[log.sessionId] = log.peso;
        sessionDates[log.sessionId] = date;
      }
    }

    final sortedSessions = maxWeightPerSession.keys.toList()
      ..sort((a, b) => sessionDates[a]!.compareTo(sessionDates[b]!));

    final spots = sortedSessions.asMap().entries.map((e) {
      final sessionId = e.value;
      return FlSpot(e.key.toDouble(), maxWeightPerSession[sessionId] ?? 0.0);
    }).toList();

    if (spots.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Histórico insuficiente para este exercício.',
            style: TextStyle(color: context.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    final minVal = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = minVal > 0 ? minVal * 0.9 : 0.0;
    final maxY = maxVal > 0 ? maxVal * 1.1 : 10.0;

    return SizedBox(
      height: 130,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => context.surfaceColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= sortedSessions.length) return null;
                  final sId = sortedSessions[idx];
                  final weight = maxWeightPerSession[sId];
                  final date = sessionDates[sId]!;
                  final dateStr =
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                  return LineTooltipItem(
                    '$weight kg\n$dateStr',
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
                reservedSize: 20,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  if (v != v.toInt().toDouble()) return const SizedBox();
                  final idx = v.toInt();
                  if (idx < 0 || idx >= sortedSessions.length)
                    return const SizedBox();
                  final sId = sortedSessions[idx];
                  final date = sessionDates[sId]!;
                  return Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(color: context.onSurface, fontSize: 8),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(0),
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
              color: AppColors.success,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.success.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
