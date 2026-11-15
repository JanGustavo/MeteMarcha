import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';

class MuscleFocusChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const MuscleFocusChart({
    super.key,
    required this.logs,
    required this.exercises,
  });

  Color _getMuscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'peito':
        return Colors.blueAccent;
      case 'costas':
        return Colors.orangeAccent;
      case 'ombro':
        return Colors.purpleAccent;
      case 'bíceps':
        return Colors.redAccent;
      case 'tríceps':
        return Colors.pinkAccent;
      case 'perna':
        return Colors.greenAccent;
      case 'quadríceps':
        return Colors.greenAccent;
      case 'posterior':
        return Colors.lightGreenAccent;
      case 'panturrilha':
        return Colors.limeAccent;
      case 'glúteo':
        return Colors.amberAccent;
      case 'core':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> muscleVolumes = {};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final exerciseMap = {for (final e in exercises) e.id: e};

    for (final log in logs) {
      final logDate = DateTime.tryParse(log.data);
      if (logDate == null || logDate.isBefore(thirtyDaysAgo)) continue;

      final ex = exerciseMap[log.exerciseId];
      if (ex == null) continue;

      final isUnilateral = ex.isUnilateral;
      final vol = LogDao.calcularVolume(log, isUnilateral: isUnilateral);

      muscleVolumes[ex.grupoMuscular] =
          (muscleVolumes[ex.grupoMuscular] ?? 0.0) + vol;
    }

    // Fallback to all logs if last 30 days is empty
    if (muscleVolumes.isEmpty) {
      for (final log in logs) {
        final ex = exerciseMap[log.exerciseId];
        if (ex == null) continue;
        final vol = LogDao.calcularVolume(log, isUnilateral: ex.isUnilateral);
        muscleVolumes[ex.grupoMuscular] =
            (muscleVolumes[ex.grupoMuscular] ?? 0.0) + vol;
      }
    }

    final totalVol = muscleVolumes.values.fold<double>(
      0.0,
      (sum, val) => sum + val,
    );

    if (muscleVolumes.isEmpty || totalVol == 0.0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Histórico de treinos insuficiente para calcular distribuição.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    // Sort muscle groups by volume desc
    final sortedEntries = muscleVolumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieSections = sortedEntries.map((entry) {
      final percentage = totalVol > 0 ? (entry.value / totalVol) * 100 : 0.0;
      final color = _getMuscleColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 35,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressSectionLabel('DISTRIBUIÇÃO DE VOLUME POR MÚSCULO'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 110,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 20,
                        sections: pieSections,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedEntries.map((entry) {
                      final percentage = totalVol > 0
                          ? (entry.value / totalVol) * 100
                          : 0.0;
                      final color = _getMuscleColor(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 4: MEDIDAS CORPORAIS
// ═══════════════════════════════════════════════════════════════════
