// lib/pages/progress/progress_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyWeights = ref.watch(weeklyWeightsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'PROGRESSO',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // ── Gráfico de peso corporal ────────────────────────────
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('PESO CORPORAL (kg)'),
                    const SizedBox(height: 16),
                    weeklyWeights.when(
                      data: (weights) => weights.length < 2
                          ? const _EmptyChart(
                              msg:
                                  'Registre seu peso pelo menos 2 semanas\npara ver o gráfico.',
                            )
                          : _WeightChart(weights: weights),
                      loading: () => const _ChartPlaceholder(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Frequência Mensal Section Label ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'FREQUÊNCIA MENSAL',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),

          // ── Frequência Mensal ───────────────────────────────────
          const _MonthlyFrequencySliver(),

          // ── Exercícios ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'EXERCÍCIOS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const _GroupingSelector(),
                ],
              ),
            ),
          ),

          const _ExerciseProgressSliver(),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Gráfico de peso corporal ─────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<WeeklyWeight> weights;
  const _WeightChart({required this.weights});

  @override
  Widget build(BuildContext context) {
    final spots = weights
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.peso))
        .toList();

    final minY = weights.map((w) => w.peso).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = weights.map((w) => w.peso).reduce((a, b) => a > b ? a : b) + 2;

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
                const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style:
                      const TextStyle(color: AppColors.onSurface, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= weights.length) return const SizedBox();
                  final parts = weights[idx].semana.split('-W');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'W${parts.length > 1 ? parts[1] : '?'}',
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 10),
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
                  strokeColor: AppColors.background,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lista de exercícios com gráfico expansível ───────────────────────────────

class _ExerciseProgressSliver extends ConsumerWidget {
  const _ExerciseProgressSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(progressReportProvider);
    final grouping = ref.watch(progressGroupingProvider);

    return reportAsync.when(
      data: (data) {
        if (data.allTrainedExercises.isEmpty) {
          return const SliverToBoxAdapter(
            child: _EmptyChart(
              msg:
                  'Conclua alguns treinos para ver\na progressão por exercício.',
            ),
          );
        }

        final List<Widget> listItems = [];

        if (grouping == ProgressGrouping.byMuscle) {
          data.groupedByMuscle.forEach((group, exercises) {
            listItems.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Text(
                  group.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
            for (final ex in exercises) {
              listItems.add(_ExerciseCard(exercise: ex));
            }
          });
        } else {
          // Agrupamento por Dia de Treino da divisão ativa
          data.groupedByDay.forEach((day, exercises) {
            final dayColor = AppColors.getWorkoutColor(day.letra);
            listItems.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: dayColor,
                      child: Text(
                        day.letra,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DIA ${day.letra} - ${day.nome.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: dayColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            for (final ex in exercises) {
              listItems.add(_ExerciseCard(exercise: ex));
            }
          });

          // Se houver exercícios de treinos anteriores ou que não estão na divisão atual:
          if (data.exercisesWithoutDay.isNotEmpty) {
            listItems.add(
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Text(
                  'OUTROS / ANTERIORES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
            for (final ex in data.exercisesWithoutDay) {
              listItems.add(_ExerciseCard(exercise: ex));
            }
          }
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => listItems[i],
            childCount: listItems.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, __) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Erro ao carregar relatório: $err'),
          ),
        ),
      ),
    );
  }
}

class _GroupingSelector extends ConsumerWidget {
  const _GroupingSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouping = ref.watch(progressGroupingProvider);

    return SegmentedButton<ProgressGrouping>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment<ProgressGrouping>(
          value: ProgressGrouping.byDay,
          label: Text('Por Dia', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.calendar_today_rounded, size: 14),
        ),
        ButtonSegment<ProgressGrouping>(
          value: ProgressGrouping.byMuscle,
          label: Text('Por Músculo', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.fitness_center_rounded, size: 14),
        ),
      ],
      selected: {grouping},
      onSelectionChanged: (newSelection) {
        ref.read(progressGroupingProvider.notifier).state = newSelection.first;
      },
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              size: 18, color: AppColors.primary),
        ),
        title: Text(exercise.nome,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${exercise.vezesFeito}× realizado · ${exercise.equipamento}${exercise.volume != null && exercise.volume!.isNotEmpty ? ' · ${exercise.volume}' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
        ),
        children: [
          FutureBuilder<List<ExerciseLog>>(
            future: ref
                .read(logDaoProvider)
                .getLogsForExerciseLastWeeks(exercise.id),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final logs = snap.data ?? [];
              if (logs.length < 2) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Mais dados necessários para o gráfico.',
                    style: TextStyle(color: AppColors.onSurface, fontSize: 13),
                  ),
                );
              }
              return _ExerciseVolumeChart(
                logs: logs,
                isUnilateral: exercise.isUnilateral,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExerciseVolumeChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final bool isUnilateral;
  const _ExerciseVolumeChart({required this.logs, required this.isUnilateral});

  @override
  Widget build(BuildContext context) {
    final spots = logs.asMap().entries.map((e) {
      final vol = LogDao.calcularVolume(e.value, isUnilateral: isUnilateral);
      return FlSpot(e.key.toDouble(), vol);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('VOLUME (kg × reps)'),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.divider, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(0),
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 9),
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
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.primary,
                      strokeWidth: 1.5,
                      strokeColor: AppColors.background,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.07),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUnilateral)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              '* Volume bilateral: peso × reps × 2',
              style: TextStyle(color: AppColors.onSurface, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.onSurface,
        fontSize: 10,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String msg;
  const _EmptyChart({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurface, height: 1.6),
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Frequência Mensal ─────────────────────────────────────────────────────────

const _portugueseMonths = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro'
];

String _getMonthName(int month) {
  if (month < 1 || month > 12) return '';
  return _portugueseMonths[month - 1];
}

class _MonthlyFrequencySliver extends ConsumerWidget {
  const _MonthlyFrequencySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySessionsAsync = ref.watch(monthlySessionsProvider);
    final daysMapAsync = ref.watch(workoutDaysMapProvider);

    return monthlySessionsAsync.when(
      data: (months) {
        if (months.isEmpty) {
          return const SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'Nenhum treino concluído ainda.\nInicie e conclua um treino para ver seu histórico mensal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurface, height: 1.5),
                  ),
                ),
              ),
            ),
          );
        }

        return daysMapAsync.when(
          data: (daysMap) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = months[index];
                  final monthName = _getMonthName(m.monthDate.month);
                  final year = m.monthDate.year;
                  final trainedDaysCount = m.sessions.map((s) {
                    try {
                      return DateTime.parse(s.data).day;
                    } catch (_) {
                      return null;
                    }
                  }).whereType<int>().toSet().length;

                  final textTrainedDays = trainedDaysCount == 1 ? '1 dia treinado' : '$trainedDaysCount dias treinados';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: index == 0,
                        title: Text(
                          '$monthName de $year'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        subtitle: Text(
                          textTrainedDays,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          const Divider(color: AppColors.divider, height: 16),
                          _MonthCalendarGrid(
                            monthDate: m.monthDate,
                            sessions: m.sessions,
                            daysMap: daysMap,
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'HISTÓRICO DE TREINOS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _MonthSessionsList(
                            sessions: m.sessions,
                            daysMap: daysMap,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: months.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (err, _) => SliverToBoxAdapter(
            child: Center(child: Text('Erro ao carregar dados dos dias: $err')),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Center(child: Text('Erro ao carregar frequência mensal: $err')),
      ),
    );
  }
}

class _MonthCalendarGrid extends StatelessWidget {
  final DateTime monthDate;
  final List<WorkoutSession> sessions;
  final Map<int, WorkoutDay> daysMap;

  const _MonthCalendarGrid({
    required this.monthDate,
    required this.sessions,
    required this.daysMap,
  });

  @override
  Widget build(BuildContext context) {
    final year = monthDate.year;
    final month = monthDate.month;
    final totalDays = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Monday, 7 = Sunday
    final leadDays = firstWeekday - 1;

    // Group sessions by day of month
    final Map<int, List<WorkoutSession>> daySessions = {};
    for (final s in sessions) {
      try {
        final d = DateTime.parse(s.data);
        daySessions.putIfAbsent(d.day, () => []).add(s);
      } catch (_) {}
    }

    final headers = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: headers
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadDays + totalDays,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index < leadDays) {
              return const SizedBox.shrink();
            }
            final dayNum = index - leadDays + 1;
            final daySess = daySessions[dayNum] ?? [];
            final hasTrained = daySess.isNotEmpty;

            Color bgColor = AppColors.surface;
            Color textColor = AppColors.onSurface;
            bool isBold = false;
            Border? border = Border.all(color: AppColors.divider, width: 0.8);

            if (hasTrained) {
              final firstSess = daySess.first;
              final wDay = daysMap[firstSess.dayId];
              bgColor = wDay != null
                  ? AppColors.getWorkoutColor(wDay.letra)
                  : AppColors.primaryLight;
              textColor = Colors.white;
              isBold = true;
              border = null;
            }

            return Tooltip(
              message: hasTrained
                  ? daySess.map((s) {
                      final wDay = daysMap[s.dayId];
                      final name = wDay != null ? 'Dia ${wDay.letra} - ${wDay.nome}' : 'Treino';
                      final dur = s.duracaoSegundos != null
                          ? ' (${s.duracaoSegundos! ~/ 60} min)'
                          : '';
                      return '$name$dur';
                    }).join('\n')
                  : 'Sem treinos',
              child: GestureDetector(
                onTap: hasTrained
                    ? () {
                        _showDaySessionsBottomSheet(context, dayNum, month, year, daySess, daysMap);
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDaySessionsBottomSheet(
    BuildContext context,
    int day,
    int month,
    int year,
    List<WorkoutSession> sessions,
    Map<int, WorkoutDay> daysMap,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Treinos do dia $day/${month.toString().padLeft(2, '0')}/$year',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final wDay = daysMap[s.dayId];
                    final name = wDay != null ? 'Dia ${wDay.letra} - ${wDay.nome}' : 'Treino';
                    final color = wDay != null ? AppColors.getWorkoutColor(wDay.letra) : AppColors.primaryLight;
                    final duration = s.duracaoSegundos != null
                        ? '${s.duracaoSegundos! ~/ 60} minutos de duração'
                        : 'Sem duração registrada';

                    return Card(
                      color: AppColors.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          child: Text(wDay?.letra ?? 'T'),
                        ),
                        title: Text(name),
                        subtitle: Text(duration),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSessionsList extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final Map<int, WorkoutDay> daysMap;

  const _MonthSessionsList({
    required this.sessions,
    required this.daysMap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        final wDay = daysMap[s.dayId];
        final name = wDay != null ? 'Dia ${wDay.letra} - ${wDay.nome}' : 'Treino';
        final color = wDay != null ? AppColors.getWorkoutColor(wDay.letra) : AppColors.primaryLight;
        final date = DateTime.tryParse(s.data);
        final dateStr = date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}'
            : '';
        final weekdayStr = date != null ? _getWeekdayAbbreviation(date.weekday) : '';
        final durationStr = s.duracaoSegundos != null
            ? '${s.duracaoSegundos! ~/ 60} min'
            : '0 min';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 65,
                child: Text(
                  '$dateStr ($weekdayStr)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 10,
                backgroundColor: color,
                child: Text(
                  wDay?.letra ?? 'T',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                durationStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getWeekdayAbbreviation(int weekday) {
    switch (weekday) {
      case 1: return 'Seg';
      case 2: return 'Ter';
      case 3: return 'Qua';
      case 4: return 'Qui';
      case 5: return 'Sex';
      case 6: return 'Sáb';
      case 7: return 'Dom';
      default: return '';
    }
  }
}
