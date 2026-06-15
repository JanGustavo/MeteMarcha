// lib/pages/progress/workout_session_detail_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/progress_extended_provider.dart';
import '../../core/theme/app_theme.dart';

// Provider para buscar os logs da sessão atual
final sessionLogsProvider = FutureProvider.family<List<ExerciseLog>, int>((ref, sessionId) async {
  final logDao = ref.read(logDaoProvider);
  return logDao.getLogsForSession(sessionId);
});

// Provider para buscar a sessão anterior concluída do mesmo treino (dayId)
final previousSessionProvider = FutureProvider.family<WorkoutSession?, WorkoutSession>((ref, currentSession) async {
  final db = ref.read(databaseProvider);
  if (currentSession.dayId == null) return null;

  return (db.select(db.workoutSessions)
        ..where((s) =>
            s.dayId.equals(currentSession.dayId!) &
            s.status.equals('concluido') &
            s.id.equals(currentSession.id).not() &
            s.data.isSmallerThanValue(currentSession.data))
        ..orderBy([(s) => OrderingTerm.desc(s.data)])
        ..limit(1))
      .getSingleOrNull();
});

// Provider para buscar os logs da sessão anterior
final previousSessionLogsProvider = FutureProvider.family<List<ExerciseLog>, int>((ref, previousSessionId) async {
  final logDao = ref.read(logDaoProvider);
  return logDao.getLogsForSession(previousSessionId);
});

class WorkoutSessionDetailPage extends ConsumerStatefulWidget {
  final WorkoutSession session;

  const WorkoutSessionDetailPage({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<WorkoutSessionDetailPage> createState() => _WorkoutSessionDetailPageState();
}

class _WorkoutSessionDetailPageState extends ConsumerState<WorkoutSessionDetailPage> {
  String _selectedMuscleFilter = 'Tudo';
  int? _expandedExerciseChartId;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);
    final daysMapAsync = ref.watch(workoutDaysMapProvider);
    final currentLogsAsync = ref.watch(sessionLogsProvider(widget.session.id));
    final previousSessionAsync = ref.watch(previousSessionProvider(widget.session));
    final allCompletedLogsAsync = ref.watch(allCompletedLogsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: daysMapAsync.when(
          data: (daysMap) {
            final wDay = daysMap[widget.session.dayId];
            return Text(
              wDay != null ? 'Treino ${wDay.letra} - ${wDay.nome}' : 'Detalhes do Treino',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
          loading: () => const Text('Carregando treino...'),
          error: (_, __) => const Text('Detalhes do Treino'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: exercisesAsync.when(
        data: (exercises) => currentLogsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return Center(
                child: Text(
                  'Nenhuma série registrada nesta sessão.',
                  style: TextStyle(color: context.onSurface),
                ),
              );
            }

            final exerciseMap = {for (final e in exercises) e.id: e};

            // Filtragem de logs
            final List<ExerciseLog> filteredLogs = logs.where((log) {
              if (_selectedMuscleFilter == 'Tudo') return true;
              final ex = exerciseMap[log.exerciseId];
              return ex?.grupoMuscular == _selectedMuscleFilter;
            }).toList();

            // Agrupa os logs por exercício preservando a ordem que foram feitos
            final Map<int, List<ExerciseLog>> logsPerExercise = {};
            final List<int> orderedExerciseIds = [];
            for (final log in filteredLogs) {
              if (!logsPerExercise.containsKey(log.exerciseId)) {
                logsPerExercise[log.exerciseId] = [];
                orderedExerciseIds.add(log.exerciseId);
              }
              logsPerExercise[log.exerciseId]!.add(log);
            }

            // Calcula estatísticas básicas da sessão
            double totalVolume = 0;
            int totalSets = 0;
            final Set<String> muscleGroupsTrained = {};

            for (final log in logs) {
              final ex = exerciseMap[log.exerciseId];
              if (ex != null) {
                final isUnilateral = ex.isUnilateral;
                final vol = log.peso * log.repeticoes * (isUnilateral && log.lado == 'ambos' ? 2 : 1);
                totalVolume += vol;
                totalSets++;
                muscleGroupsTrained.add(ex.grupoMuscular);
              }
            }

            // Carrega logs anteriores para comparação
            return previousSessionAsync.when(
              data: (prevSession) {
                if (prevSession != null) {
                  final prevLogsAsync = ref.watch(previousSessionLogsProvider(prevSession.id));
                  return prevLogsAsync.when(
                    data: (prevLogs) {
                      return _buildContent(
                        context,
                        exerciseMap,
                        orderedExerciseIds,
                        logsPerExercise,
                        prevLogs,
                        totalVolume,
                        totalSets,
                        muscleGroupsTrained.toList(),
                        allCompletedLogsAsync.value ?? [],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildContent(
                      context,
                      exerciseMap,
                      orderedExerciseIds,
                      logsPerExercise,
                      [],
                      totalVolume,
                      totalSets,
                      muscleGroupsTrained.toList(),
                      allCompletedLogsAsync.value ?? [],
                    ),
                  );
                } else {
                  return _buildContent(
                    context,
                    exerciseMap,
                    orderedExerciseIds,
                    logsPerExercise,
                    [],
                    totalVolume,
                    totalSets,
                    muscleGroupsTrained.toList(),
                    allCompletedLogsAsync.value ?? [],
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildContent(
                context,
                exerciseMap,
                orderedExerciseIds,
                logsPerExercise,
                [],
                totalVolume,
                totalSets,
                muscleGroupsTrained.toList(),
                allCompletedLogsAsync.value ?? [],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro ao carregar logs da sessão: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar exercícios: $err')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<int, Exercise> exerciseMap,
    List<int> orderedExerciseIds,
    Map<int, List<ExerciseLog>> logsPerExercise,
    List<ExerciseLog> previousLogs,
    double totalVolume,
    int totalSets,
    List<String> muscleGroups,
    List<ExerciseLog> allCompletedLogs,
  ) {
    // Agrupa logs anteriores por exercício e série para comparação direta
    final Map<int, Map<int, ExerciseLog>> prevLogsPerExAndSerie = {};
    for (final log in previousLogs) {
      prevLogsPerExAndSerie.putIfAbsent(log.exerciseId, () => {});
      prevLogsPerExAndSerie[log.exerciseId]![log.serie] = log;
    }

    final parsedDate = DateTime.tryParse(widget.session.data) ?? DateTime.now();
    final formattedDate = '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    final formattedTime = '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

    final durationMin = widget.session.duracaoSegundos != null
        ? '${widget.session.duracaoSegundos! ~/ 60}m'
        : 'Desconhecida';

    return CustomScrollView(
      slivers: [
        // Card de resumo da sessão
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$formattedDate às $formattedTime',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.onBackground,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_rounded, color: AppColors.primaryLight, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            durationMin,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: context.divider, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Volume Total', '${totalVolume.toStringAsFixed(0)} kg', Icons.fitness_center_rounded),
                    _buildStatItem('Séries', '$totalSets concluídas', Icons.playlist_add_check_rounded),
                    _buildStatItem('Músculos', '${muscleGroups.length} grupos', Icons.grid_view_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Filtros horizontais por grupo muscular
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Tudo'),
                ...muscleGroups.map((muscle) => _buildFilterChip(muscle)),
              ],
            ),
          ),
        ),

        // Exercícios
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exerciseId = orderedExerciseIds[index];
                final exercise = exerciseMap[exerciseId];
                final logs = logsPerExercise[exerciseId] ?? [];
                if (exercise == null) return const SizedBox.shrink();

                final prevMap = prevLogsPerExAndSerie[exerciseId] ?? {};
                final isExpanded = _expandedExerciseChartId == exerciseId;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: context.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do exercício
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.nome,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildBadge(exercise.grupoMuscular, AppColors.getWorkoutColor(exercise.grupoMuscular[0])),
                                      const SizedBox(width: 6),
                                      _buildBadge(exercise.equipamento, AppColors.skip),
                                      if (exercise.tempoDescansoSegundos > 0) ...[
                                        const SizedBox(width: 6),
                                        _buildBadge(
                                          'Descanso: ${_formatDescanso(exercise.tempoDescansoSegundos)}',
                                          AppColors.info,
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded ? Icons.show_chart_rounded : Icons.insert_chart_outlined_rounded,
                                color: isExpanded ? AppColors.success : context.onSurface,
                              ),
                              tooltip: 'Ver histórico de cargas',
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedExerciseChartId = null;
                                  } else {
                                    _expandedExerciseChartId = exerciseId;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        
                        // Gráfico de evolução se estiver expandido
                        if (isExpanded) ...[
                          const SizedBox(height: 16),
                          Divider(color: context.divider, height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            'EVOLUÇÃO DE CARGA MÁXIMA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LoadEvolutionChart(
                            logs: allCompletedLogs,
                            exerciseId: exerciseId,
                          ),
                        ],

                        const SizedBox(height: 16),
                        Divider(color: context.divider, height: 1),
                        const SizedBox(height: 12),

                        // Tabela de séries
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2), // Série
                            1: FlexColumnWidth(2.5), // Carga Atual
                            2: FlexColumnWidth(3.0), // Comparação Carga
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            // Header da tabela
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'SÉRIE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: context.onSurface,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'CARGA & REPS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: context.onSurface,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'VS SEMANA PASSADA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: context.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...logs.map((log) {
                              final prevLog = prevMap[log.serie];
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'S${log.serie}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: context.onBackground,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${log.peso.toStringAsFixed(1).replaceAll('.0', '')} kg',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.onBackground,
                                          ),
                                        ),
                                        Text(' × ', style: TextStyle(color: context.onSurface)),
                                        Text(
                                          '${log.repeticoes}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: _buildComparisonCell(log, prevLog),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: orderedExerciseIds.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: context.onSurface, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.onBackground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedMuscleFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedMuscleFilter = label;
            });
          }
        },
        backgroundColor: context.surfaceColor,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : context.onSurface,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Colors.transparent : context.divider,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDescanso(int segundos) {
    if (segundos < 60) return '${segundos}s';
    final min = segundos ~/ 60;
    final rest = segundos % 60;
    if (rest == 0) return '${min}min';
    return '${min}m${rest}s';
  }

  Widget _buildComparisonCell(ExerciseLog current, ExerciseLog? previous) {
    if (previous == null) {
      return Text(
        'Primeiro registro',
        style: TextStyle(fontSize: 12, color: context.onSurface, fontStyle: FontStyle.italic),
      );
    }

    final diffWeight = current.peso - previous.peso;
    final diffReps = current.repeticoes - previous.repeticoes;

    final List<Widget> items = [];

    // Comparação de carga
    if (diffWeight > 0) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward_rounded, color: AppColors.success, size: 12),
            Text(
              '+${diffWeight.toStringAsFixed(1).replaceAll('.0', '')}kg',
              style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (diffWeight < 0) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward_rounded, color: AppColors.warning, size: 12),
            Text(
              '${diffWeight.toStringAsFixed(1).replaceAll('.0', '')}kg',
              style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Comparação de repetições
    if (diffReps > 0) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (items.isNotEmpty) const SizedBox(width: 6),
            const Icon(Icons.add_rounded, color: AppColors.success, size: 12),
            Text(
              '$diffReps rep${diffReps > 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (diffReps < 0) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (items.isNotEmpty) const SizedBox(width: 6),
            const Icon(Icons.remove_rounded, color: AppColors.warning, size: 12),
            Text(
              '${diffReps.abs()} rep${diffReps.abs() > 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: context.onSurface, size: 12),
          const SizedBox(width: 4),
          Text(
            'Igual',
            style: TextStyle(color: context.onSurface, fontSize: 12),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

// Reutilizamos a classe _LoadEvolutionChart já existente no progress_page.dart.
// Porém, como ela é privada lá, recriamos aqui com foco no escopo deste módulo.
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
