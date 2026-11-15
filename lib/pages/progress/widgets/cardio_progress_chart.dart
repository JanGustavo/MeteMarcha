import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

enum CardioChartMetric { duration, distance, calories }

class CardioProgressChart extends StatefulWidget {
  final List<Cardio> cardios;

  const CardioProgressChart({super.key, required this.cardios});

  @override
  State<CardioProgressChart> createState() => _CardioProgressChartState();
}

class _CardioProgressChartState extends State<CardioProgressChart> {
  CardioChartMetric _selectedMetric = CardioChartMetric.duration;

  DateTime _startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, double> weeklyValues = {};
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);

    for (int i = 3; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
      weeklyValues[weekStart] = 0.0;
    }

    for (final c in widget.cardios) {
      final logDate = DateTime.tryParse(c.data);
      if (logDate == null) continue;
      final weekStart = _startOfWeek(logDate);
      if (weeklyValues.containsKey(weekStart)) {
        double val = 0.0;
        switch (_selectedMetric) {
          case CardioChartMetric.duration:
            val = c.duracaoSegundos / 60.0;
            break;
          case CardioChartMetric.distance:
            val = c.distanciaKm ?? 0.0;
            break;
          case CardioChartMetric.calories:
            val = (c.calorias ?? 0).toDouble();
            break;
        }
        weeklyValues[weekStart] = (weeklyValues[weekStart] ?? 0.0) + val;
      }
    }

    final sortedWeeks = weeklyValues.keys.toList()..sort();
    final spots = sortedWeeks.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), weeklyValues[e.value] ?? 0.0);
    }).toList();

    final maxVal = weeklyValues.values.isEmpty
        ? 60.0
        : weeklyValues.values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 60.0;

    final hasData = weeklyValues.values.any((v) => v > 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text(
                'Tempo',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              selected: _selectedMetric == CardioChartMetric.duration,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMetric = CardioChartMetric.duration;
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text(
                'Distância',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              selected: _selectedMetric == CardioChartMetric.distance,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMetric = CardioChartMetric.distance;
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text(
                'Calorias',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              selected: _selectedMetric == CardioChartMetric.calories,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMetric = CardioChartMetric.calories;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasData)
          SizedBox(
            height: 120,
            child: Center(
              child: Text(
                _selectedMetric == CardioChartMetric.duration
                    ? 'Nenhum minuto de cárdio registrado nas últimas semanas.'
                    : (_selectedMetric == CardioChartMetric.distance
                          ? 'Nenhuma distância de cárdio registrada nas últimas semanas.'
                          : 'Nenhuma caloria de cárdio registrada nas últimas semanas.'),
                style: TextStyle(color: context.onSurface, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: _selectedMetric == CardioChartMetric.calories
                ? LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                              context.surfaceColor,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              if (idx < 0 || idx >= sortedWeeks.length)
                                return null;
                              final weekStart = sortedWeeks[idx];
                              final val = weeklyValues[weekStart] ?? 0.0;
                              final text =
                                  'Semana ${weekStart.day}/${weekStart.month}: ${val.toStringAsFixed(0)} kcal';
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
                              if (v != v.toInt().toDouble())
                                return const SizedBox();
                              final idx = v.toInt();
                              if (idx < 0 || idx >= sortedWeeks.length)
                                return const SizedBox();
                              final text = 'S-${3 - idx}';
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  idx == 3 ? 'Atual' : text,
                                  style: TextStyle(
                                    color: context.onSurface,
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, _) {
                              return Text(
                                '${value.toInt()}',
                                style: TextStyle(
                                  color: context.onSurface,
                                  fontSize: 8,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => context.surfaceColor,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final weekStart = sortedWeeks[groupIndex];
                            final val = rod.toY;
                            String tooltipText = '';
                            if (_selectedMetric == CardioChartMetric.duration) {
                              tooltipText =
                                  'Semana ${weekStart.day}/${weekStart.month}: ${val.toStringAsFixed(0)} min';
                            } else {
                              tooltipText =
                                  'Semana ${weekStart.day}/${weekStart.month}: ${val.toStringAsFixed(1)} km';
                            }
                            return BarTooltipItem(
                              tooltipText,
                              TextStyle(
                                color: context.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
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
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= sortedWeeks.length)
                                return const SizedBox();
                              final text = 'S-${3 - idx}';
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  idx == 3 ? 'Atual' : text,
                                  style: TextStyle(
                                    color: context.onSurface,
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, _) {
                              final suffix =
                                  _selectedMetric == CardioChartMetric.duration
                                  ? 'm'
                                  : 'k';
                              return Text(
                                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix',
                                style: TextStyle(
                                  color: context.onSurface,
                                  fontSize: 8,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: context.divider, strokeWidth: 1),
                      ),
                      barGroups: spots.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.y,
                              color: AppColors.primary,
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
      ],
    );
  }
}
