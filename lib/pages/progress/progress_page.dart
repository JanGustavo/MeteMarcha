// lib/pages/progress/progress_page.dart

import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/progress_extended_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/decimal_input_formatter.dart';
import 'workout_session_detail_page.dart';
import '../../core/services/health_connect_service.dart';

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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progresso 📈'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'PESO & FREQ'),
              Tab(text: 'CARGAS & RECS'),
              Tab(text: 'METAS & VOL'),
              Tab(text: 'MEDIDAS'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: context.onSurface,
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

                  final plateaus = _detectPlateaus(logs, exercises);

                  return ListView(
                    children: [
                      if (plateaus.isNotEmpty)
                        _PlateauWarningWidget(plateaus: plateaus),
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
                                initialValue: exercises.any((e) => e.id == _selectedExerciseIdForEvolution)
                                    ? _selectedExerciseIdForEvolution
                                    : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar Exercício',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                dropdownColor: context.cardColor,
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
            
            // Tab 4: Medidas Corporais
            const _BodyMeasurementsTab(),
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
                    color: insight.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: insight.color.withValues(alpha: 0.25),
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
                            color: context.onBackground.withValues(alpha: 0.95),
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
                FlLine(color: context.divider, strokeWidth: 1),
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
                      TextStyle(color: context.onSurface, fontSize: 10),
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
                      style: TextStyle(
                          color: context.onSurface, fontSize: 10),
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
}

// ─── Lista de exercícios com gráfico expansível ───────────────────────────────

/*
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
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Text(
                  'OUTROS / ANTERIORES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
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
*/

/*
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
*/

/*
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              size: 18, color: AppColors.primary),
        ),
        title: Text(exercise.nome,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${exercise.vezesFeito}× realizado · ${exercise.equipamento}${exercise.volume != null && exercise.volume!.isNotEmpty ? ' · ${exercise.volume}' : ''}',
          style: TextStyle(fontSize: 12, color: context.onSurface),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Mais dados necessários para o gráfico.',
                    style: TextStyle(color: context.onSurface, fontSize: 13),
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

    if (spots.isEmpty) {
      return SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Nenhum volume de treino registrado.',
            style: TextStyle(color: context.onSurface, fontSize: 12),
          ),
        ),
      );
    }

    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 10.0;

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
                  getTooltipColor: (touchedSpot) => context.surfaceColor,
                  getTooltipItems: (touchedSpots) {
                     return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      if (idx < 0 || idx >= logs.length) return null;
                      final log = logs[idx];
                      final vol = LogDao.calcularVolume(log, isUnilateral: isUnilateral);
                      return LineTooltipItem(
                        '${log.peso} kg × ${log.repeticoes} reps\nVol: ${vol.toStringAsFixed(0)} kg',
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
                      style: TextStyle(
                          color: context.onSurface, fontSize: 9),
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
                      strokeColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.07),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUnilateral)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '* Volume bilateral: peso × reps × 2',
              style: TextStyle(color: context.onSurface, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
*/

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.onSurface,
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
          style: TextStyle(color: context.onSurface, height: 1.6),
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
          return SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'Nenhum treino concluído ainda.\nInicie e conclua um treino para ver seu histórico mensal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.onSurface, height: 1.5),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: context.onSurface,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Divider(color: context.divider, height: 16),
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.onSurface,
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

            Color bgColor = context.surfaceColor;
            Color textColor = context.onSurface;
            bool isBold = false;
            Border? border = Border.all(color: context.divider, width: 0.8);

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
      backgroundColor: context.cardColor,
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.onBackground,
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
                      color: context.surfaceColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          child: Text(wDay?.letra ?? 'T'),
                        ),
                        title: Text(name),
                        subtitle: Text(duration),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.onSurface,
                        ),
                        onTap: () {
                          Navigator.pop(ctx); // Fecha o bottom sheet
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WorkoutSessionDetailPage(session: s),
                            ),
                          );
                        },
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

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutSessionDetailPage(session: s),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 65,
                  child: Text(
                    '$dateStr ($weekdayStr)',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurface,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: context.onSurface,
                ),
              ],
            ),
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
                  final text = '${dateToFormat(weekStart)}: ${vol.toStringAsFixed(0)} kg';
                  return LineTooltipItem(
                    text,
                    TextStyle(color: context.onBackground, fontWeight: FontWeight.bold, fontSize: 10),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: context.divider, strokeWidth: 1),
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
                    child: Text(text, style: TextStyle(color: context.onSurface, fontSize: 8)),
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
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
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
                  final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                  return LineTooltipItem(
                    '$weight kg\n$dateStr',
                    TextStyle(color: context.onBackground, fontWeight: FontWeight.bold, fontSize: 10),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: context.divider, strokeWidth: 1),
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
                    style: TextStyle(color: context.onSurface, fontSize: 8),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0), style: TextStyle(color: context.onSurface, fontSize: 9)),
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
              belowBarData: BarAreaData(show: true, color: AppColors.success.withValues(alpha: 0.06)),
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
        equipamento: ex.equipamento,
      );
    }).whereType<_RecordItem>().toList()
      ..sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

    if (recordItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Nenhum recorde registrado ainda.', style: TextStyle(color: context.onSurface)),
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
  final String? equipamento;

  const _RecordItem({
    required this.exerciseName,
    required this.maxWeight,
    required this.repsAtMax,
    required this.estimated1RM,
    required this.date,
    this.equipamento,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        title: Text(exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Recorde em: $dateStr', style: TextStyle(fontSize: 11, color: context.onSurface)),
        trailing: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            final isBodyweight = equipamento?.trim().toLowerCase() == 'peso corporal';
            final textMsg = isBodyweight
                ? '1RM Estimada (Peso Corporal): Para exercícios livres, a carga considerada é a fração do seu peso corporal de fato ativada (ex: Flexão = 65%, Barra = 100%). A 1RM é estimada pela fórmula científica de Epley: Carga Efetiva × (1 + Reps / 30). Este cálculo é amplamente embasado na fisiologia do exercício (Epley, 1985) para estimar com segurança a força máxima sem os riscos de lesão de um teste de carga física real.'
                : '1RM Estimada (One-Rep Max): A carga máxima teórica que você consegue levantar para 1 repetição, estimada pela fórmula clássica de Epley: Peso × (1 + Reps / 30). Validada na literatura científica (Epley, 1985) para prever a capacidade máxima de força a partir de séries submáximas realizadas até a falha.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  textMsg,
                  style: const TextStyle(fontSize: 13),
                ),
                duration: const Duration(seconds: 6),
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
      final currentMax = maxLoads[log.exerciseId];
      if (currentMax == null || log.peso > currentMax) {
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Nenhuma meta definida. Defina metas para peso corporal ou carga de exercício!',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.onSurface, fontSize: 13),
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
                                  : AppColors.primaryLight.withValues(alpha: 0.6),
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
                                  style: TextStyle(fontSize: 10, color: context.onSurface),
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
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nova Meta',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                decoration: InputDecoration(
                  labelText: 'Tipo de Meta',
                  labelStyle: TextStyle(color: context.onSurface, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  prefixIcon: Icon(Icons.category_rounded, color: context.onSurface, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.divider, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
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
                const SizedBox(height: 16),
                if (exercises.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cadastre exercícios para definir metas de carga.',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<Exercise>(
                    initialValue: exercises.contains(selectedExercise) ? selectedExercise : null,
                    dropdownColor: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      labelText: 'Selecione o Exercício',
                      labelStyle: TextStyle(color: context.onSurface, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      prefixIcon: Icon(Icons.fitness_center_rounded, color: context.onSurface, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.divider, width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: exercises.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.nome, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedExercise = val;
                      });
                    },
                  ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Valor Alvo',
                  labelStyle: TextStyle(color: context.onSurface, fontSize: 13),
                  hintText: '80.0',
                  suffixText: 'kg',
                  suffixStyle: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  prefixIcon: Icon(Icons.ads_click_rounded, color: context.onSurface, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.divider, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: context.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  concluido: false,
                );

                ref.read(goalsProvider.notifier).addGoal(newGoal);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
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
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Registre seu peso corporal no perfil para calcular seu Índice de Força Relativa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurface, fontSize: 13),
          ),
        ),
      );
    }

    final Map<String, double> best1RMPerGroup = {
      'Peito': 0.0,
      'Perna': 0.0,
      'Costas': 0.0,
    };
    final Map<String, double> bestRaw1RMPerGroup = {
      'Peito': 0.0,
      'Perna': 0.0,
      'Costas': 0.0,
    };
    final Map<String, String> bestExerciseNamePerGroup = {};

    final exerciseMap = {for (final e in exercises) e.id: e};

    for (final log in logs) {
      final ex = exerciseMap[log.exerciseId];
      if (ex == null) continue;

      final equip = ex.equipamento.trim().toLowerCase();
      final nameLower = ex.nome.trim().toLowerCase();
      final muscle = ex.grupoMuscular;
      
      double factor = 1.0;
      
      final isLeg = muscle == 'Quadríceps' ||
                    muscle == 'Posterior' ||
                    muscle == 'Panturrilha' ||
                    muscle == 'Perna';
      
      final isMachine = equip == 'máquina' ||
                        equip == 'maquina' ||
                        equip == 'aparelho' ||
                        equip == 'articulado' ||
                        equip == 'guiado' ||
                        nameLower.contains('máquina') ||
                        nameLower.contains('maquina') ||
                        nameLower.contains('aparelho') ||
                        nameLower.contains('leg press') ||
                        nameLower.contains('hack');
                        
      final isCableOrSmith = equip == 'cabo' ||
                             equip == 'smith' ||
                             equip == 'polia' ||
                             nameLower.contains('cabo') ||
                             nameLower.contains('smith') ||
                             nameLower.contains('polia');

      if (isLeg && isMachine) {
        factor = 0.6; // 40% de desconto para máquinas de perna
      } else if (isMachine) {
        factor = 0.8; // 20% de desconto para outras máquinas
      } else if (isCableOrSmith) {
        factor = 0.9; // 10% de desconto para polias e Smith
      }
      
      final String mappedGroup;
      if (isLeg) {
        mappedGroup = 'Perna';
      } else {
        mappedGroup = muscle;
      }
      
      if (best1RMPerGroup.containsKey(mappedGroup)) {
        final raw1RM = log.peso * (1 + log.repeticoes / 30.0);
        final oneRepMax = raw1RM * factor;
        final currentBest = best1RMPerGroup[mappedGroup] ?? 0.0;
        if (oneRepMax > currentBest) {
          best1RMPerGroup[mappedGroup] = oneRepMax;
          bestRaw1RMPerGroup[mappedGroup] = raw1RM;
          bestExerciseNamePerGroup[mappedGroup] = ex.nome;
        }
      }
    }

    final double peitoRatio = userWeight > 0 ? (best1RMPerGroup['Peito']! / userWeight) : 0.0;
    final double costasRatio = userWeight > 0 ? (best1RMPerGroup['Costas']! / userWeight) : 0.0;
    final double pernaRatio = userWeight > 0 ? (best1RMPerGroup['Perna']! / userWeight) : 0.0;

    double getGroupScore(double ratio, List<double> thresholds) {
      if (ratio <= 0.0) return 1.0;
      final t1 = thresholds[0];
      final t2 = thresholds[1];
      final t3 = thresholds[2];
      if (ratio < t1) {
        return 1.0 + (ratio / t1);
      } else if (ratio < t2) {
        return 2.0 + (ratio - t1) / (t2 - t1);
      } else if (ratio < t3) {
        return 3.0 + (ratio - t2) / (t3 - t2);
      } else {
        return (4.0 + (ratio - t3) / (t3 * 0.5)).clamp(4.0, 5.0);
      }
    }

    final peitoScore = getGroupScore(peitoRatio, const [0.5, 0.9, 1.3]);
    final costasScore = getGroupScore(costasRatio, const [0.5, 0.8, 1.2]);
    final pernaScore = getGroupScore(pernaRatio, const [0.8, 1.3, 1.8]);

    final overallScore = (peitoScore + costasScore + pernaScore) / 3.0;
    final totalBest1RM = best1RMPerGroup.values.fold<double>(0.0, (sum, val) => sum + val);

    String levelName = 'Iniciante';
    double nextLevelScore = 2.0;
    double prevLevelScore = 1.0;
    Color levelColor = Colors.blueAccent;
    bool isMaxLevel = false;

    if (overallScore < 2.0) {
      levelName = 'Iniciante (Nível 1)';
      nextLevelScore = 2.0;
      prevLevelScore = 1.0;
      levelColor = Colors.blueAccent;
    } else if (overallScore < 3.0) {
      levelName = 'Intermediário (Nível 2)';
      nextLevelScore = 3.0;
      prevLevelScore = 2.0;
      levelColor = AppColors.primaryLight;
    } else if (overallScore < 4.0) {
      levelName = 'Avançado (Nível 3)';
      nextLevelScore = 4.0;
      prevLevelScore = 3.0;
      levelColor = AppColors.success;
    } else {
      levelName = 'Elite (Nível 4)';
      nextLevelScore = 4.0;
      prevLevelScore = 4.0;
      levelColor = Colors.amber;
      isMaxLevel = true;
    }

    final ratioProgress = isMaxLevel
        ? 1.0
        : (nextLevelScore > prevLevelScore
            ? ((overallScore - prevLevelScore) / (nextLevelScore - prevLevelScore)).clamp(0.0, 1.0)
            : 1.0);

    return GestureDetector(
      onTap: () {
        _showRelativeStrengthLevelsDialog(
          context: context,
          overallScore: overallScore,
          peitoScore: peitoScore,
          costasScore: costasScore,
          pernaScore: pernaScore,
          peitoRatio: peitoRatio,
          costasRatio: costasRatio,
          pernaRatio: pernaRatio,
          totalBest1RM: totalBest1RM,
          userWeight: userWeight,
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
                        'Índice Geral: ${overallScore.toStringAsFixed(2)} / 4.00 (Média de Níveis)',
                        style: TextStyle(fontSize: 12, color: context.onSurface),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: levelColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      'Nível ${overallScore.toStringAsFixed(1)}',
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
                    'Nível ${prevLevelScore.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: context.onSurface),
                  ),
                  if (isMaxLevel)
                    const Text(
                      'Nível Máximo Atingido 👑',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                    )
                  else
                    Text(
                      'Próximo nível: Nível ${nextLevelScore.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: levelColor),
                    ),
                ],
              ),
              Divider(color: context.divider, height: 24),
              const Text(
                'MELHORES ESTIMATIVAS DE 1RM (AJUSTADAS):',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              _buildMuscleStrengthRow(
                groupName: 'Peito (Empurrar)',
                oneRM: best1RMPerGroup['Peito']!,
                rawOneRM: bestRaw1RMPerGroup['Peito']!,
                exerciseName: bestExerciseNamePerGroup['Peito'],
                bodyWeight: userWeight,
                groupScore: peitoScore,
              ),
              _buildMuscleStrengthRow(
                groupName: 'Costas (Puxar)',
                oneRM: best1RMPerGroup['Costas']!,
                rawOneRM: bestRaw1RMPerGroup['Costas']!,
                exerciseName: bestExerciseNamePerGroup['Costas'],
                bodyWeight: userWeight,
                groupScore: costasScore,
              ),
              _buildMuscleStrengthRow(
                groupName: 'Perna (Agachar)',
                oneRM: best1RMPerGroup['Perna']!,
                rawOneRM: bestRaw1RMPerGroup['Perna']!,
                exerciseName: bestExerciseNamePerGroup['Perna'],
                bodyWeight: userWeight,
                groupScore: pernaScore,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleStrengthRow({
    required String groupName,
    required double oneRM,
    required double rawOneRM,
    required String? exerciseName,
    required double bodyWeight,
    required double groupScore,
  }) {
    final ratio = bodyWeight > 0 ? oneRM / bodyWeight : 0.0;
    
    String groupLevel = 'Nenhum';
    Color levelColor = Colors.white30;
    if (oneRM > 0) {
      if (groupScore < 2.0) {
        groupLevel = 'Iniciante';
        levelColor = Colors.blueAccent;
      } else if (groupScore < 3.0) {
        groupLevel = 'Intermediário';
        levelColor = AppColors.primaryLight;
      } else if (groupScore < 4.0) {
        groupLevel = 'Avançado';
        levelColor = AppColors.success;
      } else {
        groupLevel = 'Elite';
        levelColor = Colors.amber;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(groupName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    if (oneRM > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: levelColor.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          groupLevel.toUpperCase(),
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
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
                Text(
                  '${ratio.toStringAsFixed(2)}x Peso${rawOneRM > oneRM ? ' (${rawOneRM.toStringAsFixed(0)} kg real)' : ''}',
                  style: const TextStyle(fontSize: 10, color: AppColors.primaryLight),
                ),
              ],
            )
          else
            const Text('-', style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }

  void _showRelativeStrengthLevelsDialog({
    required BuildContext context,
    required double overallScore,
    required double peitoScore,
    required double costasScore,
    required double pernaScore,
    required double peitoRatio,
    required double costasRatio,
    required double pernaRatio,
    required double totalBest1RM,
    required double userWeight,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final textColor = context.onBackground;
        final subtextColor = context.onSurface;

        Widget buildLevelItem({
          required String title,
          required String subtitle,
          required String range,
          required String details,
          required Color color,
          required bool isActive,
          required String levelNum,
        }) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? color : context.divider,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isActive ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      levelNum,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          color: subtextColor.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      range,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          'VOCÊ ESTÁ AQUI',
                          style: TextStyle(
                            color: color,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Níveis de Força',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O Nível de Força é a média dos níveis atingidos em Peito, Costas e Pernas. Cada grupo muscular possui padrões específicos. Para evitar distorções de polias e alavancas, exercícios em máquinas e cabos recebem um fator de correção (ex: polias/smith = -10%, máquinas = -20%, máquinas de perna = -40%).',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.divider.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seu peso: ${userWeight.toStringAsFixed(1)} kg',
                            style: TextStyle(fontSize: 11, color: subtextColor),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Nível Geral',
                                style: TextStyle(fontSize: 10, color: subtextColor),
                              ),
                              Text(
                                '${overallScore.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Colors.white10),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Peito', style: TextStyle(fontSize: 9, color: Colors.white60)),
                                Text('${peitoRatio.toStringAsFixed(2)}x (Nível ${peitoScore.toStringAsFixed(1)})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Costas', style: TextStyle(fontSize: 9, color: Colors.white60)),
                                Text('${costasRatio.toStringAsFixed(2)}x (Nível ${costasScore.toStringAsFixed(1)})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Perna', style: TextStyle(fontSize: 9, color: Colors.white60)),
                                Text('${pernaRatio.toStringAsFixed(2)}x (Nível ${pernaScore.toStringAsFixed(1)})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                buildLevelItem(
                  title: 'Iniciante (Nível 1)',
                  subtitle: 'Fase de adaptação muscular',
                  range: '< Nível 2',
                  details: 'Peito < 0.5x | Costas < 0.5x | Perna < 0.8x',
                  color: Colors.blueAccent,
                  isActive: overallScore < 2.0,
                  levelNum: '1',
                ),
                buildLevelItem(
                  title: 'Intermediário (Nível 2)',
                  subtitle: 'Base sólida de força',
                  range: 'Nível 2 a 3',
                  details: 'Peito: 0.5x - 0.9x | Costas: 0.5x - 0.8x | Perna: 0.8x - 1.3x',
                  color: AppColors.primaryLight,
                  isActive: overallScore >= 2.0 && overallScore < 3.0,
                  levelNum: '2',
                ),
                buildLevelItem(
                  title: 'Avançado (Nível 3)',
                  subtitle: 'Nível de força expressivo',
                  range: 'Nível 3 a 4',
                  details: 'Peito: 0.9x - 1.3x | Costas: 0.8x - 1.2x | Perna: 1.3x - 1.8x',
                  color: AppColors.success,
                  isActive: overallScore >= 3.0 && overallScore < 4.0,
                  levelNum: '3',
                ),
                buildLevelItem(
                  title: 'Elite (Nível 4)',
                  subtitle: 'Força digna de atletas',
                  range: '≥ Nível 4',
                  details: 'Peito ≥ 1.3x | Costas ≥ 1.2x | Perna ≥ 1.8x',
                  color: Colors.amber,
                  isActive: overallScore >= 4.0,
                  levelNum: '4',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('ENTENDI'),
            ),
          ],
        );
      },
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

    final totalVol = muscleVolumes.values.fold<double>(0.0, (sum, val) => sum + val);

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
                              style: TextStyle(fontSize: 11, color: context.onSurface),
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

class _BodyMeasurementsTab extends ConsumerStatefulWidget {
  const _BodyMeasurementsTab();

  @override
  ConsumerState<_BodyMeasurementsTab> createState() => _BodyMeasurementsTabState();
}

class _BodyMeasurementsTabState extends ConsumerState<_BodyMeasurementsTab> {
  String _selectedChartMetric = 'Peso';

  void _showAddEditMeasurementSheet([BodyMeasurement? measurement]) {
    final profile = ref.read(profileProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _AddEditMeasurementSheet(
                measurement: measurement,
                userHeight: profile?.altura,
                onSave: (entry) async {
                  final dao = ref.read(profileDaoProvider);
                  if (measurement != null) {
                    final toUpdate = BodyMeasurement(
                      id: measurement.id,
                      data: entry.data.value,
                      peso: entry.peso.value,
                      gorduraPercentual: entry.gorduraPercentual.value,
                      massaMagra: entry.massaMagra.value,
                      imc: entry.imc.value,
                      peito: entry.peito.value,
                      cintura: entry.cintura.value,
                      bracoEsquerdo: entry.bracoEsquerdo.value,
                      bracoDireito: entry.bracoDireito.value,
                      coxaEsquerda: entry.coxaEsquerda.value,
                      coxaDireita: entry.coxaDireita.value,
                      panturrilhaEsquerda: entry.panturrilhaEsquerda.value,
                      panturrilhaDireita: entry.panturrilhaDireita.value,
                      fotoPath: entry.fotoPath.value,
                    );
                    await dao.updateMeasurement(toUpdate);
                    
                    if (toUpdate.peso != null) {
                      final date = DateTime.tryParse(toUpdate.data) ?? DateTime.now();
                      await HealthConnectService.instance.syncBodyMeasurement(
                        weightKg: toUpdate.peso!,
                        bodyFatPercent: toUpdate.gorduraPercentual,
                        bmi: toUpdate.imc,
                        dateTime: date,
                      );
                    }
                  } else {
                    await dao.insertMeasurement(entry);
                    
                    if (entry.peso.value != null) {
                      final date = DateTime.tryParse(entry.data.value ?? '') ?? DateTime.now();
                      await HealthConnectService.instance.syncBodyMeasurement(
                        weightKg: entry.peso.value!,
                        bodyFatPercent: entry.gorduraPercentual.value,
                        bmi: entry.imc.value,
                        dateTime: date,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMeasurement(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro?'),
        content: const Text('Tem certeza que deseja apagar este registro de medidas? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Excluir', style: TextStyle(color: AppColors.primary)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final dao = ref.read(profileDaoProvider);
      await dao.deleteMeasurement(id);
    }
  }

  Widget _buildMetricSelector() {
    final metrics = [
      'Peso',
      'Gordura %',
      'Massa Magra',
      'IMC',
      'Peito',
      'Cintura',
      'Braço D.',
      'Braço E.',
      'Coxa D.',
      'Coxa E.',
      'Panturrilha D.',
      'Panturrilha E.',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: metrics.map((m) {
          final isSelected = _selectedChartMetric == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(m),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedChartMetric = m;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryLight : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);

    return measurementsAsync.when(
      data: (measurements) {
        if (measurements.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 64,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.onSurface.withValues(alpha: 0.5)
                        : AppColors.lightOnSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum registro de medidas ainda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe seu peso, percentual de gordura, medidas corporais e tire fotos de progresso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditMeasurementSheet(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar Medidas'),
                  ),
                ],
              ),
            ),
          );
        }

        final latest = measurements.first;
        final prev = measurements.length > 1 ? measurements[1] : null;

        // Calculate trends
        final weightDiff = (latest.peso != null && prev?.peso != null) ? latest.peso! - prev!.peso! : 0.0;
        final fatDiff = (latest.gorduraPercentual != null && prev?.gorduraPercentual != null) ? latest.gorduraPercentual! - prev!.gorduraPercentual! : 0.0;
        final leanDiff = (latest.massaMagra != null && prev?.massaMagra != null) ? latest.massaMagra! - prev!.massaMagra! : 0.0;
        final imcDiff = (latest.imc != null && prev?.imc != null) ? latest.imc! - prev!.imc! : 0.0;

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Core stats dashboard
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                children: [
                  _MetricSummaryCard(
                    title: 'PESO',
                    value: latest.peso != null ? '${latest.peso!.toStringAsFixed(1)} kg' : 'N/A',
                    change: latest.peso != null && prev?.peso != null ? '${weightDiff > 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg' : '',
                    isPositiveChange: weightDiff >= 0,
                    icon: Icons.monitor_weight_outlined,
                    color: AppColors.info,
                  ),
                  _MetricSummaryCard(
                    title: 'GORDURA',
                    value: latest.gorduraPercentual != null ? '${latest.gorduraPercentual!.toStringAsFixed(1)}%' : 'N/A',
                    change: latest.gorduraPercentual != null && prev?.gorduraPercentual != null ? '${fatDiff > 0 ? "+" : ""}${fatDiff.toStringAsFixed(1)}%' : '',
                    isPositiveChange: fatDiff <= 0,
                    icon: Icons.percent_rounded,
                    color: AppColors.warning,
                  ),
                  _MetricSummaryCard(
                    title: 'MASSA MAGRA',
                    value: latest.massaMagra != null ? '${latest.massaMagra!.toStringAsFixed(1)} kg' : 'N/A',
                    change: latest.massaMagra != null && prev?.massaMagra != null ? '${leanDiff > 0 ? "+" : ""}${leanDiff.toStringAsFixed(1)} kg' : '',
                    isPositiveChange: leanDiff >= 0,
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.success,
                  ),
                  _MetricSummaryCard(
                    title: 'IMC',
                    value: latest.imc != null ? latest.imc!.toStringAsFixed(1) : 'N/A',
                    change: latest.imc != null && prev?.imc != null ? '${imcDiff > 0 ? "+" : ""}${imcDiff.toStringAsFixed(1)}' : '',
                    isPositiveChange: imcDiff <= 0,
                    icon: Icons.calculate_outlined,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),
            ),

            // Evolution Chart Card
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionLabel('EVOLUÇÃO HISTÓRICA'),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricSelector(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MeasurementsChart(
                        measurements: measurements,
                        metric: _selectedChartMetric,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel('HISTÓRICO'),
                  IconButton.filledTonal(
                    onPressed: () => _showAddEditMeasurementSheet(),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // History List
            ...measurements.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final itemPrev = idx + 1 < measurements.length ? measurements[idx + 1] : null;
              return _MeasurementCard(
                measurement: item,
                previous: itemPrev,
                onEdit: () => _showAddEditMeasurementSheet(item),
                onDelete: () => _deleteMeasurement(item.id),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Erro ao carregar medidas: $e')),
    );
  }
}

// ── Metric Summary Card ──────────────────────────────────────────────────────

class _MetricSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositiveChange;
  final IconData icon;
  final Color color;

  const _MetricSummaryCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositiveChange,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.08);
    final borderColor = isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? context.onSurface : AppColors.lightOnSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? context.onBackground : AppColors.lightOnBackground,
            ),
          ),
          const SizedBox(height: 4),
          if (change.isNotEmpty)
            Row(
              children: [
                Icon(
                  isPositiveChange ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 10,
                  color: isPositiveChange ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPositiveChange ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Sem histórico',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Evolution Chart ──────────────────────────────────────────────────────────

class _MeasurementsChart extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  final String metric;

  const _MeasurementsChart({
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
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  if (idx < 0 || idx >= chartData.length) return const SizedBox();
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

class _MeasurementCard extends StatefulWidget {
  final BodyMeasurement measurement;
  final BodyMeasurement? previous;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeasurementCard({
    required this.measurement,
    this.previous,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<_MeasurementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.measurement;
    final prev = widget.previous;
    final date = DateTime.tryParse(m.data) ?? DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            title: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (m.peso != null)
                    _buildMiniBadge('Peso', '${m.peso!.toStringAsFixed(1)} kg', prev?.peso, isWeight: true),
                  if (m.gorduraPercentual != null)
                    _buildMiniBadge('Gordura', '${m.gorduraPercentual!.toStringAsFixed(1)}%', prev?.gorduraPercentual, isFat: true),
                  if (m.massaMagra != null)
                    _buildMiniBadge('Massa M.', '${m.massaMagra!.toStringAsFixed(1)} kg', prev?.massaMagra, isLeanMass: true),
                  if (m.imc != null)
                    _buildMiniBadge('IMC', m.imc!.toStringAsFixed(1), prev?.imc),
                ],
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: context.onSurface,
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasAnyCircumference(m)) ...[
                    const Text(
                      'Medidas de Circunferência',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3.5,
                      ),
                      children: [
                        if (m.peito != null) _buildCircumferenceTile('Peito', m.peito!, prev?.peito),
                        if (m.cintura != null) _buildCircumferenceTile('Cintura', m.cintura!, prev?.cintura, lowerIsBetter: true),
                        if (m.bracoDireito != null) _buildCircumferenceTile('Braço D.', m.bracoDireito!, prev?.bracoDireito),
                        if (m.bracoEsquerdo != null) _buildCircumferenceTile('Braço E.', m.bracoEsquerdo!, prev?.bracoEsquerdo),
                        if (m.coxaDireita != null) _buildCircumferenceTile('Coxa D.', m.coxaDireita!, prev?.coxaDireita),
                        if (m.coxaEsquerda != null) _buildCircumferenceTile('Coxa E.', m.coxaEsquerda!, prev?.coxaEsquerda),
                        if (m.panturrilhaDireita != null) _buildCircumferenceTile('Panturrilha D.', m.panturrilhaDireita!, prev?.panturrilhaDireita),
                        if (m.panturrilhaEsquerda != null) _buildCircumferenceTile('Panturrilha E.', m.panturrilhaEsquerda!, prev?.panturrilhaEsquerda),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (m.fotoPath != null) ...[
                    const Text(
                      'Foto de Progresso',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _FullscreenImageViewer(
                              imagePath: m.fotoPath!,
                              dateStr: dateStr,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: isDark ? context.surfaceColor : AppColors.lightSurface,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.file(
                                File(m.fotoPath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Imagem não encontrada',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Toque para ampliar',
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Editar', style: TextStyle(fontSize: 12)),
                        onPressed: widget.onEdit,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? context.onBackground : AppColors.lightOnBackground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Excluir', style: TextStyle(fontSize: 12)),
                        onPressed: widget.onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAnyCircumference(BodyMeasurement m) {
    return m.peito != null ||
        m.cintura != null ||
        m.bracoEsquerdo != null ||
        m.bracoDireito != null ||
        m.coxaEsquerda != null ||
        m.coxaDireita != null ||
        m.panturrilhaEsquerda != null ||
        m.panturrilhaDireita != null;
  }

  Widget _buildMiniBadge(
    String label,
    String value,
    double? prevVal, {
    bool isWeight = false,
    bool isFat = false,
    bool isLeanMass = false,
  }) {
    Color? diffColor;
    String diffText = '';

    if (prevVal != null) {
      final currentVal = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (currentVal != null) {
        final diff = currentVal - prevVal;
        if (diff != 0) {
          final sign = diff > 0 ? '+' : '';
          diffText = ' ($sign${diff.toStringAsFixed(1)})';
          
          if (isFat) {
            diffColor = diff < 0 ? AppColors.success : AppColors.primary;
          } else if (isWeight || isLeanMass) {
            diffColor = diff > 0 ? AppColors.success : AppColors.primary;
          }
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? context.onSurface : AppColors.lightOnSurface,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? context.onBackground : AppColors.lightOnBackground,
              ),
            ),
            if (diffText.isNotEmpty)
              TextSpan(
                text: diffText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: diffColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircumferenceTile(String label, double val, double? prevVal, {bool lowerIsBetter = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String diffText = '';
    Color? diffColor;

    if (prevVal != null) {
      final diff = val - prevVal;
      if (diff != 0) {
        final sign = diff > 0 ? '+' : '';
        diffText = ' $sign${diff.toStringAsFixed(1)} cm';
        if (lowerIsBetter) {
          diffColor = diff < 0 ? AppColors.success : AppColors.primary;
        } else {
          diffColor = diff > 0 ? AppColors.success : AppColors.primary;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? context.onSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${val.toStringAsFixed(1)} cm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? context.onBackground : AppColors.lightOnBackground,
                ),
              ),
              if (diffText.isNotEmpty) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    diffText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: diffColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add/Edit Measurement Bottom Sheet ────────────────────────────────────────

class _AddEditMeasurementSheet extends StatefulWidget {
  final BodyMeasurement? measurement;
  final double? userHeight;
  final Function(BodyMeasurementsCompanion entry) onSave;

  const _AddEditMeasurementSheet({
    this.measurement,
    this.userHeight,
    required this.onSave,
  });

  @override
  State<_AddEditMeasurementSheet> createState() => _AddEditMeasurementSheetState();
}

class _AddEditMeasurementSheetState extends State<_AddEditMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  
  final _pesoCtrl = TextEditingController();
  final _gorduraCtrl = TextEditingController();
  final _massaMagraCtrl = TextEditingController();
  final _peitoCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _bracoECtrl = TextEditingController();
  final _bracoDCtrl = TextEditingController();
  final _coxaECtrl = TextEditingController();
  final _coxaDCtrl = TextEditingController();
  final _panturrilhaECtrl = TextEditingController();
  final _panturrilhaDCtrl = TextEditingController();

  File? _selectedImage;
  String? _existingPhotoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _selectedDate = m != null ? DateTime.tryParse(m.data) ?? DateTime.now() : DateTime.now();
    
    if (m != null) {
      _pesoCtrl.text = m.peso?.toString() ?? '';
      _gorduraCtrl.text = m.gorduraPercentual?.toString() ?? '';
      _massaMagraCtrl.text = m.massaMagra?.toString() ?? '';
      _peitoCtrl.text = m.peito?.toString() ?? '';
      _cinturaCtrl.text = m.cintura?.toString() ?? '';
      _bracoECtrl.text = m.bracoEsquerdo?.toString() ?? '';
      _bracoDCtrl.text = m.bracoDireito?.toString() ?? '';
      _coxaECtrl.text = m.coxaEsquerda?.toString() ?? '';
      _coxaDCtrl.text = m.coxaDireita?.toString() ?? '';
      _panturrilhaECtrl.text = m.panturrilhaEsquerda?.toString() ?? '';
      _panturrilhaDCtrl.text = m.panturrilhaDireita?.toString() ?? '';
      _existingPhotoPath = m.fotoPath;
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _gorduraCtrl.dispose();
    _massaMagraCtrl.dispose();
    _peitoCtrl.dispose();
    _cinturaCtrl.dispose();
    _bracoECtrl.dispose();
    _bracoDCtrl.dispose();
    _coxaECtrl.dispose();
    _coxaDCtrl.dispose();
    _panturrilhaECtrl.dispose();
    _panturrilhaDCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _existingPhotoPath = null;
        });
      }
    } catch (_) {}
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _existingPhotoPath = null;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final peso = double.tryParse(_pesoCtrl.text);
    final gordura = double.tryParse(_gorduraCtrl.text);
    final massaMagra = double.tryParse(_massaMagraCtrl.text);
    final peito = double.tryParse(_peitoCtrl.text);
    final cintura = double.tryParse(_cinturaCtrl.text);
    final bracoE = double.tryParse(_bracoECtrl.text);
    final bracoD = double.tryParse(_bracoDCtrl.text);
    final coxaE = double.tryParse(_coxaECtrl.text);
    final coxaD = double.tryParse(_coxaDCtrl.text);
    final panturrilhaE = double.tryParse(_panturrilhaECtrl.text);
    final panturrilhaD = double.tryParse(_panturrilhaDCtrl.text);

    if (peso == null &&
        gordura == null &&
        massaMagra == null &&
        peito == null &&
        cintura == null &&
        bracoE == null &&
        bracoD == null &&
        coxaE == null &&
        coxaD == null &&
        panturrilhaE == null &&
        panturrilhaD == null &&
        _selectedImage == null &&
        _existingPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha pelo menos um campo ou adicione uma foto!')),
      );
      return;
    }

    String? fotoPath = _existingPhotoPath;
    if (_selectedImage != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/progress_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await _selectedImage!.copy('${photosDir.path}/$fileName');
      fotoPath = savedFile.path;
    }

    double? imc;
    if (peso != null && widget.userHeight != null && widget.userHeight! > 0) {
      final hM = widget.userHeight! / 100;
      imc = peso / (hM * hM);
    }

    final dateStr = _selectedDate.toIso8601String().split('T')[0];

    final entry = BodyMeasurementsCompanion(
      id: widget.measurement != null ? Value(widget.measurement!.id) : const Value.absent(),
      data: Value(dateStr),
      peso: Value(peso),
      gorduraPercentual: Value(gordura),
      massaMagra: Value(massaMagra),
      imc: Value(imc),
      peito: Value(peito),
      cintura: Value(cintura),
      bracoEsquerdo: Value(bracoE),
      bracoDireito: Value(bracoD),
      coxaEsquerda: Value(coxaE),
      coxaDireita: Value(coxaD),
      panturrilhaEsquerda: Value(panturrilhaE),
      panturrilhaDireita: Value(panturrilhaD),
      fotoPath: Value(fotoPath),
    );

    widget.onSave(entry);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.measurement == null ? 'Nova Medida' : 'Editar Medida',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight),
                title: const Text('Data do Registro', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            const _SectionLabel('COMPOSIÇÃO CORPORAL'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pesoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _gorduraCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Gordura (%)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _massaMagraCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Massa M. (kg)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const _SectionLabel('CIRCUNFERÊNCIAS (cm)'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(_peitoCtrl, 'Peito'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_cinturaCtrl, 'Cintura'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(_bracoDCtrl, 'Braço Direito'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_bracoECtrl, 'Braço Esquerdo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(_coxaDCtrl, 'Coxa Direita'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_coxaECtrl, 'Coxa Esquerda'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(_panturrilhaDCtrl, 'Panturrilha Dir.'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_panturrilhaECtrl, 'Panturrilha Esq.'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionLabel('FOTO DE PROGRESSO'),
            const SizedBox(height: 12),
            _buildPhotoPickerSection(isDark),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [DecimalInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: (val) {
        if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
          return 'Inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoPickerSection(bool isDark) {
    final hasPhoto = _selectedImage != null || _existingPhotoPath != null;

    if (hasPhoto) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_existingPhotoPath!), width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                onPressed: _removePhoto,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 32, color: isDark ? Colors.white60 : Colors.black45),
            const SizedBox(height: 8),
            Text(
              'Tirar ou escolher foto de progresso',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fullscreen Image Viewer ──────────────────────────────────────────────────

class _FullscreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String dateStr;

  const _FullscreenImageViewer({
    required this.imagePath,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Foto de Progresso - $dateStr',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'Não foi possível carregar a imagem.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Plateau Detection & Warning ──────────────────────────────────────────────

class _PlateauInfo {
  final Exercise exercise;
  final double currentMax1RM;
  final double previousMax1RM;
  final double previous2Max1RM;
  final double lastSessionMaxWeight;
  final double suggestedDeloadWeight;

  _PlateauInfo({
    required this.exercise,
    required this.currentMax1RM,
    required this.previousMax1RM,
    required this.previous2Max1RM,
    required this.lastSessionMaxWeight,
    required this.suggestedDeloadWeight,
  });
}

List<_PlateauInfo> _detectPlateaus(List<ExerciseLog> logs, List<Exercise> exercises) {
  final List<_PlateauInfo> plateaus = [];

  final Map<int, List<ExerciseLog>> logsByExercise = {};
  for (final log in logs) {
    logsByExercise.putIfAbsent(log.exerciseId, () => []).add(log);
  }

  for (final exercise in exercises) {
    final exerciseLogs = logsByExercise[exercise.id];
    if (exerciseLogs == null || exerciseLogs.isEmpty) continue;

    final List<int> sessionIds = [];
    final Map<int, List<ExerciseLog>> logsBySession = {};
    for (final log in exerciseLogs) {
      if (!logsBySession.containsKey(log.sessionId)) {
        sessionIds.add(log.sessionId);
        logsBySession[log.sessionId] = [];
      }
      logsBySession[log.sessionId]!.add(log);
    }

    if (sessionIds.length >= 3) {
      final sN_2 = sessionIds[sessionIds.length - 3];
      final sN_1 = sessionIds[sessionIds.length - 2];
      final sN = sessionIds[sessionIds.length - 1];

      double getMax1RM(List<ExerciseLog> sessionLogs) {
        double maxVal = 0.0;
        for (final l in sessionLogs) {
          final oneRM = l.repeticoes == 1 ? l.peso : l.peso * (1 + l.repeticoes / 30.0);
          if (oneRM > maxVal) {
            maxVal = oneRM;
          }
        }
        return maxVal;
      }

      final oneRMN_2 = getMax1RM(logsBySession[sN_2]!);
      final oneRMN_1 = getMax1RM(logsBySession[sN_1]!);
      final oneRMN = getMax1RM(logsBySession[sN]!);

      if (oneRMN <= oneRMN_1 && oneRMN_1 <= oneRMN_2) {
        double maxWeight = 0.0;
        for (final l in logsBySession[sN]!) {
          if (l.peso > maxWeight) {
            maxWeight = l.peso;
          }
        }

        plateaus.add(_PlateauInfo(
          exercise: exercise,
          currentMax1RM: oneRMN,
          previousMax1RM: oneRMN_1,
          previous2Max1RM: oneRMN_2,
          lastSessionMaxWeight: maxWeight,
          suggestedDeloadWeight: maxWeight * 0.9,
        ));
      }
    }
  }

  return plateaus;
}

class _PlateauWarningWidget extends StatelessWidget {
  final List<_PlateauInfo> plateaus;

  const _PlateauWarningWidget({required this.plateaus});

  @override
  Widget build(BuildContext context) {
    if (plateaus.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withValues(alpha: 0.08),
              AppColors.warning.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alerta de Platô & Deload ⚠️',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Identificamos estagnação nas últimas 3 sessões:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.onBackground.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plateaus.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = plateaus[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.exercise.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${p.currentMax1RM.toStringAsFixed(1)} kg max 1RM',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_down_rounded,
                              color: AppColors.primaryLight,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.onBackground.withValues(alpha: 0.9),
                                      ),
                                  children: [
                                    const TextSpan(text: 'Sugestão: Realize um '),
                                    const TextSpan(
                                      text: 'Deload de 10%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '. Use no próximo treino a carga máxima de ',
                                    ),
                                    TextSpan(
                                      text: '${p.suggestedDeloadWeight.toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' (anterior: ${p.lastSessionMaxWeight.toStringAsFixed(1)} kg).',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
