import 'widgets/calisthenics_progress_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/progress/exercise_comparison_page.dart';
import 'package:gym_tracker/core/utils/premium_page_route.dart';
import 'package:gym_tracker/core/services/health_connect_service.dart';
import 'package:gym_tracker/pages/progress/widgets/workout_insights_card.dart';
import 'package:gym_tracker/pages/progress/widgets/fatigue_insights_card.dart';
import 'package:gym_tracker/pages/progress/widgets/weight_chart.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';
import 'package:gym_tracker/pages/progress/widgets/monthly_frequency_sliver.dart';
import 'package:gym_tracker/pages/progress/widgets/weekly_volume_chart.dart';
import 'package:gym_tracker/pages/progress/widgets/load_evolution_chart.dart';
import 'package:gym_tracker/pages/progress/widgets/personal_records_list.dart';
import 'package:gym_tracker/pages/progress/widgets/goals_manager.dart';
import 'package:gym_tracker/pages/progress/widgets/relative_strength_card.dart';
import 'package:gym_tracker/pages/progress/widgets/muscle_focus_chart.dart';
import 'package:gym_tracker/pages/progress/widgets/body_measurements_tab.dart';
import 'package:gym_tracker/pages/progress/widgets/plateau_warning_card.dart';
import 'package:gym_tracker/pages/progress/widgets/cardio_tab.dart';
import 'package:gym_tracker/pages/progress/logic/plateau_detection.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  int? _selectedExerciseIdForEvolution;

  @override
  void initState() {
    super.initState();
    _syncHealthConnectBodyData();
  }

  void _syncHealthConnectBodyData() async {
    final enabled = await HealthConnectService.instance.isEnabled();
    if (enabled) {
      final dao = ref.read(profileDaoProvider);
      await HealthConnectService.instance.syncBidirectionalMeasurements(dao);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyWeights = ref.watch(weeklyWeightsProvider);
    final completedLogsAsync = ref.watch(allCompletedLogsProvider).whenData(
        (logs) => logs.where((l) => l.trainingMetrics == null).toList());
    final exercisesAsync = ref.watch(allExercisesProvider);
    final profileAsync = ref.watch(profileProvider);

    return DefaultTabController(
      length: 6,
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
              Tab(text: 'CÁRDIO'),
              Tab(text: 'CALISTENIA'),
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
                const SliverToBoxAdapter(child: WorkoutInsightsCard()),
                const SliverToBoxAdapter(child: FatigueInsightsCard()),
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProgressSectionLabel('PESO CORPORAL (kg)'),
                          const SizedBox(height: 16),
                          weeklyWeights.when(
                            data: (weights) => weights.length < 2
                                ? const ProgressEmptyChart(
                                    msg:
                                        'Registre seu peso pelo menos 2 semanas\npara ver o gráfico.',
                                  )
                                : WeightChart(weights: weights),
                            loading: () => const ProgressChartPlaceholder(),
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
                const MonthlyFrequencySliver(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),

            // Tab 2: Cargas & Recordes
            completedLogsAsync.when(
              data: (logs) => exercisesAsync.when(
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return const Center(
                      child: Text('Nenhum exercício cadastrado.'),
                    );
                  }

                  final hasSelected = exercises.any(
                    (e) => e.id == _selectedExerciseIdForEvolution,
                  );
                  if ((_selectedExerciseIdForEvolution == null ||
                          !hasSelected) &&
                      exercises.isNotEmpty) {
                    _selectedExerciseIdForEvolution = exercises.first.id;
                  }

                  final selectedExercise = exercises.firstWhere(
                    (e) => e.id == _selectedExerciseIdForEvolution,
                    orElse: () => exercises.first,
                  );

                  final profile = profileAsync.value;
                  final userWeight = profile?.pesoAtual ?? 0.0;

                  final plateaus = detectPlateaus(logs, exercises);

                  return ListView(
                    children: [
                      if (plateaus.isNotEmpty)
                        PlateauWarningCard(plateaus: plateaus),
                      // Card de Evolução de Cargas
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ProgressSectionLabel('EVOLUÇÃO DE CARGAS'),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                initialValue: exercises.any(
                                  (e) =>
                                      e.id == _selectedExerciseIdForEvolution,
                                )
                                    ? _selectedExerciseIdForEvolution
                                    : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar Exercício',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                dropdownColor: context.cardColor,
                                items: exercises.map((e) {
                                  return DropdownMenuItem(
                                    value: e.id,
                                    child: Text(e.nome),
                                  );
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
                              LoadEvolutionChart(
                                logs: logs,
                                exerciseId: selectedExercise.id,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PremiumPageRoute(
                                        page: ExerciseComparisonPage(
                                          initialExerciseId:
                                              selectedExercise.id,
                                          initialExerciseName:
                                              selectedExercise.nome,
                                        ),
                                        transitionType:
                                            TransitionType.slideRight,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.table_chart_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Ver Tabela Comparativa Completa',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Índice de Força Relativa
                      RelativeStrengthCard(
                        logs: logs,
                        exercises: exercises,
                        userWeight: userWeight,
                      ),

                      // Recordes Pessoais
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: ProgressSectionLabel('RECORDES PESSOAIS'),
                      ),
                      PersonalRecordsList(logs: logs, exercises: exercises),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Erro ao carregar exercícios.')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Erro ao carregar histórico.')),
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
                              const ProgressSectionLabel(
                                'VOLUME DE TREINO SEMANAL (kg)',
                              ),
                              const SizedBox(height: 16),
                              WeeklyVolumeChart(
                                logs: logs,
                                exercises: exercises,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Foco Muscular (Volume por Músculo)
                      MuscleFocusChart(logs: logs, exercises: exercises),

                      // Gerenciador de Metas
                      GoalsManager(logs: logs, exercises: exercises),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Erro ao carregar exercícios.')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Erro ao carregar histórico.')),
            ),

            // Tab 4: Medidas Corporais
            const BodyMeasurementsTab(),
            const CardioTab(),
            const CalisthenicsProgressTab(),
          ],
        ),
      ),
    );
  }
}
