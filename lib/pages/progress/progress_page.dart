// lib/pages/progress/progress_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/progress_extended_provider.dart';
import '../../core/theme/app_theme.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  int? _selectedExerciseIdForEvolution;

  @override
  Widget build(BuildContext context) {
    final weeklyWeights = ref.watch(weeklyWeightsProvider);
    final completedLogsAsync = ref.watch(allCompletedLogsProvider);
    final exercisesAsync = ref.watch(allExercisesProvider);
    final profileAsync = ref.watch(profileProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progresso 📈'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'PESO & FREQ'),
              Tab(text: 'CARGAS & RECS'),
              Tab(text: 'METAS & VOL'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.onSurface,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Peso & Frequência
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: _WorkoutInsightsWidget(),
                ),
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                                    msg: 'Registre seu peso pelo menos 2 semanas\npara ver o gráfico.',
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
                const _MonthlyFrequencySliver(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),

            // Tab 2: Cargas & Recordes
            completedLogsAsync.when(
              data: (logs) => exercisesAsync.when(
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return const Center(child: Text('Nenhum exercício cadastrado.'));
                  }
                  
                  final hasSelected = exercises.any((e) => e.id == _selectedExerciseIdForEvolution);
                  if ((_selectedExerciseIdForEvolution == null || !hasSelected) && exercises.isNotEmpty) {
                    _selectedExerciseIdForEvolution = exercises.first.id;
                  }

                  final selectedExercise = exercises.firstWhere(
                    (e) => e.id == _selectedExerciseIdForEvolution,
                    orElse: () => exercises.first,
                  );

                  final profile = profileAsync.value;
                  final userWeight = profile?.pesoAtual ?? 0.0;

                  return ListView(
                    children: [
                      // Card de Evolução de Cargas
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('EVOLUÇÃO DE CARGAS'),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                value: _selectedExerciseIdForEvolution,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar Exercício',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                dropdownColor: AppColors.card,
                                items: exercises.map((e) {
                                  return DropdownMenuItem(value: e.id, child: Text(e.nome));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedExerciseIdForEvolution = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _LoadEvolutionChart(
                                logs: logs,
                                exerciseId: selectedExercise.id,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Índice de Força Relativa
                      _RelativeStrengthCard(
                        logs: logs,
                        exercises: exercises,
                        userWeight: userWeight,
                      ),

                      // Recordes Pessoais
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: _SectionLabel('RECORDES PESSOAIS'),
                      ),
                      _PersonalRecordsList(logs: logs, exercises: exercises),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Erro ao carregar exercícios.')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Erro ao carregar histórico.')),
            ),

            // Tab 3: Metas & Volume
            completedLogsAsync.when(
              data: (logs) => exercisesAsync.when(
                data: (exercises) {
                  return ListView(
                    children: [
                      // Card de Volume Semanal
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('VOLUME DE TREINO SEMANAL (kg)'),
                              const SizedBox(height: 16),
                              _WeeklyVolumeChart(logs: logs, exercises: exercises),
                            ],
                          ),
                        ),
                      ),

                      // Foco Muscular (Volume por Músculo)
                      _MuscleFocusChart(logs: logs, exercises: exercises),

                      // Gerenciador de Metas
                      _GoalsManager(logs: logs, exercises: exercises),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Erro ao carregar exercícios.')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Erro ao carregar histórico.')),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutInsightsWidget extends ConsumerWidget {
  const _WorkoutInsightsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(automaticInsightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryLight, size: 16),
              const SizedBox(width: 6),
              Text(
                'INSIGHTS DA SEMANA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: insight.color.withOpacity(0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(insight.icon, color: insight.color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  if (v != v.toInt().toDouble()) return const SizedBox();
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => AppColors.surface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      if (idx < 0 || idx >= logs.length) return null;
                      final log = logs[idx];
                      final vol = LogDao.calcularVolume(log, isUnilateral: isUnilateral);
                      return LineTooltipItem(
                        '${log.peso} kg × ${log.repeticoes} reps\nVol: ${vol.toStringAsFixed(0)} kg',
                        const TextStyle(
                          color: AppColors.onBackground,
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

// ─── Extended Progress Widgets ──────────────────────────────────────────────────

class _WeeklyVolumeChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const _WeeklyVolumeChart({required this.logs, required this.exercises});

  DateTime _startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
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
      return const SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Nenhum volume de treino registrado nas últimas semanas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurface, fontSize: 12),
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
              getTooltipColor: (touchedSpot) => AppColors.surface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= sortedWeeks.length) return null;
                  final weekStart = sortedWeeks[idx];
                  final vol = weeklyVolumes[weekStart] ?? 0.0;
                  final text = '${dateToFormat(weekStart)}: ${vol.toStringAsFixed(0)} kg';
                  return LineTooltipItem(
                    text,
                    const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold, fontSize: 10),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  if (v != v.toInt().toDouble()) return const SizedBox();
                  final idx = v.toInt();
                  if (idx < 0 || idx >= sortedWeeks.length) return const SizedBox();
                  final date = sortedWeeks[idx];
                  final text = '${date.day}/${date.month}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(text, style: const TextStyle(color: AppColors.onSurface, fontSize: 8)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0),
                  style: const TextStyle(color: AppColors.onSurface, fontSize: 9),
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
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
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

class _LoadEvolutionChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final int exerciseId;

  const _LoadEvolutionChart({required this.logs, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    final exLogs = logs.where((l) => l.exerciseId == exerciseId).toList();
    if (exLogs.length < 2) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Histórico insuficiente para este exercício.',
            style: TextStyle(color: AppColors.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    final Map<int, double> maxWeightPerSession = {};
    final Map<int, DateTime> sessionDates = {};
    for (final log in exLogs) {
      final date = DateTime.tryParse(log.data) ?? DateTime.now();
      final currentMax = maxWeightPerSession[log.sessionId] ?? 0.0;
      if (log.peso > currentMax) {
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

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return SizedBox(
      height: 130,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => AppColors.surface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= sortedSessions.length) return null;
                  final sId = sortedSessions[idx];
                  final weight = maxWeightPerSession[sId];
                  final date = sessionDates[sId]!;
                  final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                  return LineTooltipItem(
                    '$weight kg\n$dateStr',
                    const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold, fontSize: 10),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  if (v != v.toInt().toDouble()) return const SizedBox();
                  final idx = v.toInt();
                  if (idx < 0 || idx >= sortedSessions.length) return const SizedBox();
                  final sId = sortedSessions[idx];
                  final date = sessionDates[sId]!;
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(color: AppColors.onSurface, fontSize: 8),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0), style: const TextStyle(color: AppColors.onSurface, fontSize: 9)),
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
              belowBarData: BarAreaData(show: true, color: AppColors.success.withOpacity(0.06)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalRecordsList extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const _PersonalRecordsList({required this.logs, required this.exercises});

  @override
  Widget build(BuildContext context) {
    final Map<int, ExerciseLog> maxLogs = {};
    for (final log in logs) {
      final existing = maxLogs[log.exerciseId];
      if (existing == null || log.peso > existing.peso) {
        maxLogs[log.exerciseId] = log;
      }
    }

    final exerciseMap = {for (final e in exercises) e.id: e};
    final recordItems = maxLogs.entries.map((entry) {
      final ex = exerciseMap[entry.key];
      final log = entry.value;
      if (ex == null) return null;
      
      final oneRepMax = log.peso * (1 + log.repeticoes / 30.0);
      return _RecordItem(
        exerciseName: ex.nome,
        maxWeight: log.peso,
        repsAtMax: log.repeticoes,
        estimated1RM: oneRepMax,
        date: DateTime.tryParse(log.data) ?? DateTime.now(),
      );
    }).whereType<_RecordItem>().toList()
      ..sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

    if (recordItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Nenhum recorde registrado ainda.', style: TextStyle(color: AppColors.onSurface)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recordItems.length,
      itemBuilder: (context, index) => recordItems[index],
    );
  }
}

class _RecordItem extends StatelessWidget {
  final String exerciseName;
  final double maxWeight;
  final int repsAtMax;
  final double estimated1RM;
  final DateTime date;

  const _RecordItem({
    required this.exerciseName,
    required this.maxWeight,
    required this.repsAtMax,
    required this.estimated1RM,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        title: Text(exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Recorde em: $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.onSurface)),
        trailing: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '1RM Estimada (One-Rep Max): A carga máxima teórica que você consegue levantar para 1 repetição, estimada pela fórmula de Epley: Peso × (1 + Reps / 30).',
                  style: TextStyle(fontSize: 13),
                ),
                duration: Duration(seconds: 4),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${maxWeight.toStringAsFixed(1)} kg × $repsAtMax reps', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryLight, fontSize: 13)),
                Text('1RM Est: ${estimated1RM.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsManager extends ConsumerWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const _GoalsManager({required this.logs, required this.exercises});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final profile = ref.watch(profileProvider).value;

    final Map<int, double> maxLoads = {};
    for (final log in logs) {
      final currentMax = maxLoads[log.exerciseId] ?? 0.0;
      if (log.peso > currentMax) {
        maxLoads[log.exerciseId] = log.peso;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('MINHAS METAS'),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('NOVA META', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => _showAddGoalDialog(context, ref, profile?.pesoAtual ?? 0.0, maxLoads),
              ),
            ],
          ),
        ),
        if (goals.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Nenhuma meta definida. Defina metas para peso corporal ou carga de exercício!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurface, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              double currentVal = 0.0;
              double progress = 0.0;

              if (goal.tipo == 'peso') {
                currentVal = profile?.pesoAtual ?? 0.0;
                final initialVal = goal.valorInicial ?? currentVal;
                if (initialVal == goal.valorAlvo) {
                  progress = 1.0;
                } else if (initialVal > goal.valorAlvo) {
                  // Perda de peso
                  if (currentVal <= goal.valorAlvo) {
                    progress = 1.0;
                  } else if (currentVal >= initialVal) {
                    progress = 0.0;
                  } else {
                    progress = (initialVal - currentVal) / (initialVal - goal.valorAlvo);
                  }
                } else {
                  // Ganho de peso
                  if (currentVal >= goal.valorAlvo) {
                    progress = 1.0;
                  } else if (currentVal <= initialVal) {
                    progress = 0.0;
                  } else {
                    progress = (currentVal - initialVal) / (goal.valorAlvo - initialVal);
                  }
                }
              } else {
                currentVal = maxLoads[goal.exercicioId] ?? 0.0;
                final initialVal = goal.valorInicial ?? 0.0;
                if (currentVal >= goal.valorAlvo) {
                  progress = 1.0;
                } else if (initialVal >= goal.valorAlvo) {
                  progress = 1.0;
                } else if (currentVal <= initialVal) {
                  progress = 0.0;
                } else {
                  progress = (currentVal - initialVal) / (goal.valorAlvo - initialVal);
                }
              }
              if (progress > 1.0) progress = 1.0;
              if (progress < 0.0) progress = 0.0;

              final isCompleted = goal.concluido ||
                  (currentVal > 0 &&
                      (goal.tipo == 'peso'
                          ? ((goal.valorInicial ?? currentVal) > goal.valorAlvo
                              ? currentVal <= goal.valorAlvo
                              : currentVal >= goal.valorAlvo)
                          : currentVal >= goal.valorAlvo));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isCompleted
                                  ? AppColors.success
                                  : AppColors.primaryLight.withOpacity(0.6),
                              size: 22,
                            ),
                            onPressed: () => ref.read(goalsProvider.notifier).toggleGoal(goal.id),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.tipo == 'peso' ? 'Meta de Peso Corporal' : 'Meta de Carga: ${goal.exercicioNome}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Criada em: ${goal.dataCriacao}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.onSurface),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => ref.read(goalsProvider.notifier).deleteGoal(goal.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Atual: ${currentVal.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Alvo: ${goal.valorAlvo.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(isCompleted ? AppColors.success : AppColors.primaryLight),
                        ),
                      ),
                      if (isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Meta Atingida! Parabéns! 🎉',
                                style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref, double currentWeight, Map<int, double> maxLoads) {
    String selectedType = 'peso';
    Exercise? selectedExercise;
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Nova Meta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tipo de Meta'),
                items: const [
                  DropdownMenuItem(value: 'peso', child: Text('Peso Corporal')),
                  DropdownMenuItem(value: 'carga', child: Text('Carga de Exercício')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedType = val;
                    });
                  }
                },
              ),
              if (selectedType == 'carga') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Exercise>(
                  value: selectedExercise,
                  decoration: const InputDecoration(labelText: 'Selecione o Exercício'),
                  items: exercises.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.nome));
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedExercise = val;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor Alvo (kg)',
                  hintText: '80.0',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final target = double.tryParse(valueController.text.replaceAll(',', '.'));
                if (target == null || target <= 0) return;

                if (selectedType == 'carga' && selectedExercise == null) return;

                final nowStr = '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
                
                final initialVal = selectedType == 'peso'
                    ? currentWeight
                    : (maxLoads[selectedExercise!.id] ?? 0.0);

                final newGoal = Goal(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  tipo: selectedType,
                  exercicioId: selectedType == 'carga' ? selectedExercise!.id : null,
                  exercicioNome: selectedType == 'carga' ? selectedExercise!.nome : null,
                  valorAlvo: target,
                  valorInicial: initialVal,
                  dataCriacao: nowStr,
                );

                ref.read(goalsProvider.notifier).addGoal(newGoal);
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelativeStrengthCard extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;
  final double userWeight;

  const _RelativeStrengthCard({
    required this.logs,
    required this.exercises,
    required this.userWeight,
  });

  @override
  Widget build(BuildContext context) {
    if (userWeight <= 0) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Registre seu peso corporal no perfil para calcular seu Índice de Força Relativa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurface, fontSize: 13),
          ),
        ),
      );
    }

    final Map<String, double> best1RMPerGroup = {
      'Peito': 0.0,
      'Perna': 0.0,
      'Costas': 0.0,
    };
    final Map<String, String> bestExerciseNamePerGroup = {};

    final exerciseMap = {for (final e in exercises) e.id: e};

    for (final log in logs) {
      final ex = exerciseMap[log.exerciseId];
      if (ex == null) continue;
      
      final muscle = ex.grupoMuscular;
      if (best1RMPerGroup.containsKey(muscle)) {
        final oneRepMax = log.peso * (1 + log.repeticoes / 30.0);
        final currentBest = best1RMPerGroup[muscle] ?? 0.0;
        if (oneRepMax > currentBest) {
          best1RMPerGroup[muscle] = oneRepMax;
          bestExerciseNamePerGroup[muscle] = ex.nome;
        }
      }
    }

    final totalBest1RM = best1RMPerGroup.values.fold<double>(0.0, (sum, val) => sum + val);
    final strengthRatio = totalBest1RM / userWeight;

    String levelName = 'Iniciante';
    double nextLevelRatio = 1.5;
    double prevLevelRatio = 0.0;
    Color levelColor = Colors.blueAccent;

    if (strengthRatio < 1.5) {
      levelName = 'Iniciante (Nível 1)';
      nextLevelRatio = 1.5;
      prevLevelRatio = 0.0;
      levelColor = Colors.blueAccent;
    } else if (strengthRatio < 3.0) {
      levelName = 'Intermediário (Nível 2)';
      nextLevelRatio = 3.0;
      prevLevelRatio = 1.5;
      levelColor = AppColors.primaryLight;
    } else if (strengthRatio < 4.5) {
      levelName = 'Avançado (Nível 3)';
      nextLevelRatio = 4.5;
      prevLevelRatio = 3.0;
      levelColor = AppColors.success;
    } else {
      levelName = 'Elite (Nível 4)';
      nextLevelRatio = 6.0;
      prevLevelRatio = 4.5;
      levelColor = Colors.amber;
    }

    final ratioProgress = nextLevelRatio > prevLevelRatio
        ? ((strengthRatio - prevLevelRatio) / (nextLevelRatio - prevLevelRatio)).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Índice de Força Relativa: A soma das estimativas de 1RM em Peito, Costas e Perna, dividida pelo seu peso corporal. Mede sua força proporcional ao seu tamanho.',
              style: TextStyle(fontSize: 13),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('FORÇA RELATIVA (BENCHMARK)'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: levelColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soma 1RM: ${totalBest1RM.toStringAsFixed(1)} kg (${strengthRatio.toStringAsFixed(2)}x peso)',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: levelColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      '${strengthRatio.toStringAsFixed(1)}x',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: levelColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratioProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(levelColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${prevLevelRatio.toStringAsFixed(1)}x',
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurface),
                  ),
                  Text(
                    'Próximo nível: ${nextLevelRatio.toStringAsFixed(1)}x',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: levelColor),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 24),
              const Text(
                'MELHORES ESTIMATIVAS DE 1RM:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              _buildMuscleStrengthRow('Peito (Empurrar)', best1RMPerGroup['Peito']!, bestExerciseNamePerGroup['Peito'], userWeight),
              _buildMuscleStrengthRow('Costas (Puxar)', best1RMPerGroup['Costas']!, bestExerciseNamePerGroup['Costas'], userWeight),
              _buildMuscleStrengthRow('Perna (Agachar)', best1RMPerGroup['Perna']!, bestExerciseNamePerGroup['Perna'], userWeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleStrengthRow(String groupName, double oneRM, String? exerciseName, double bodyWeight) {
    final ratio = bodyWeight > 0 ? oneRM / bodyWeight : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                if (exerciseName != null && oneRM > 0)
                  Text(
                    exerciseName,
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const Text('Nenhum registro', style: TextStyle(fontSize: 10, color: Colors.white30)),
              ],
            ),
          ),
          if (oneRM > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${oneRM.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('${ratio.toStringAsFixed(2)}x Peso', style: const TextStyle(fontSize: 10, color: AppColors.primaryLight)),
              ],
            )
          else
            const Text('-', style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }
}

class _MuscleFocusChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const _MuscleFocusChart({required this.logs, required this.exercises});

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

      muscleVolumes[ex.grupoMuscular] = (muscleVolumes[ex.grupoMuscular] ?? 0.0) + vol;
    }

    // Fallback to all logs if last 30 days is empty
    if (muscleVolumes.isEmpty) {
      for (final log in logs) {
        final ex = exerciseMap[log.exerciseId];
        if (ex == null) continue;
        final vol = LogDao.calcularVolume(log, isUnilateral: ex.isUnilateral);
        muscleVolumes[ex.grupoMuscular] = (muscleVolumes[ex.grupoMuscular] ?? 0.0) + vol;
      }
    }

    if (muscleVolumes.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Histórico de treinos insuficiente para calcular distribuição.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    final totalVol = muscleVolumes.values.fold<double>(0.0, (sum, val) => sum + val);
    
    // Sort muscle groups by volume desc
    final sortedEntries = muscleVolumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieSections = sortedEntries.map((entry) {
      final percentage = totalVol > 0 ? (entry.value / totalVol) * 100 : 0.0;
      final color = _getMuscleColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 35,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('DISTRIBUIÇÃO DE VOLUME POR MÚSCULO'),
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
                      final percentage = totalVol > 0 ? (entry.value / totalVol) * 100 : 0.0;
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
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurface),
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
