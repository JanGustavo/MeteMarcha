import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class MeasurementsChart extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  final String metric;

  const MeasurementsChart({
    super.key,
    required this.measurements,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = measurements.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < chartData.length; i++) {
      final val = _getValueForMetric(chartData[i], metric);
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }

    if (spots.length < 2) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'Registre este dado em pelo menos 2 datas\ndiferentes para ver o gráfico de evolução.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.onSurface
                : AppColors.lightOnSurface,
            fontSize: 12,
          ),
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.05;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.onSurface
                        : AppColors.lightOnSurface,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  if (v != v.toInt().toDouble()) return const SizedBox();
                  final idx = v.toInt();
                  if (idx < 0 || idx >= chartData.length)
                    return const SizedBox();
                  final date = DateTime.tryParse(chartData[idx].data);
                  if (date == null) return const SizedBox();
                  final day = date.day.toString().padLeft(2, '0');
                  final month = date.month.toString().padLeft(2, '0');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$day/$month',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.onSurface
                            : AppColors.lightOnSurface,
                        fontSize: 9,
                      ),
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
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
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

  double? _getValueForMetric(BodyMeasurement m, String metric) {
    switch (metric) {
      case 'Peso':
        return m.peso;
      case 'Gordura %':
        return m.gorduraPercentual;
      case 'Massa Magra':
        return m.massaMagra;
      case 'IMC':
        return m.imc;
      case 'Peito':
        return m.peito;
      case 'Cintura':
        return m.cintura;
      case 'Braço E.':
        return m.bracoEsquerdo;
      case 'Braço D.':
        return m.bracoDireito;
      case 'Coxa E.':
        return m.coxaEsquerda;
      case 'Coxa D.':
        return m.coxaDireita;
      case 'Panturrilha E.':
        return m.panturrilhaEsquerda;
      case 'Panturrilha D.':
        return m.panturrilhaDireita;
      default:
        return null;
    }
  }
}

// ── Measurement Card ─────────────────────────────────────────────────────────
