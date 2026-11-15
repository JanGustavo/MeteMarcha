import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/decimal_input_formatter.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';

class GoalsManager extends ConsumerWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const GoalsManager({super.key, required this.logs, required this.exercises});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final profile = ref.watch(profileProvider).value;
    final cardiosAsync = ref.watch(cardiosProvider);
    final cardios = cardiosAsync.value ?? [];

    final Map<int, double> maxLoads = {};
    for (final log in logs) {
      final currentMax = maxLoads[log.exerciseId];
      if (currentMax == null || log.peso > currentMax) {
        maxLoads[log.exerciseId] = log.peso;
      }
    }

    double maxCardioDistance = 0.0;
    double maxCardioDurationMin = 0.0;
    for (final c in cardios) {
      if (c.distanciaKm != null && c.distanciaKm! > maxCardioDistance) {
        maxCardioDistance = c.distanciaKm!;
      }
      final durationMin = c.duracaoSegundos / 60.0;
      if (durationMin > maxCardioDurationMin) {
        maxCardioDurationMin = durationMin;
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
              const ProgressSectionLabel('MINHAS METAS'),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('NOVA META', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => _showAddGoalDialog(
                  context,
                  ref,
                  profile?.pesoAtual ?? 0.0,
                  maxLoads,
                  cardios,
                ),
              ),
            ],
          ),
        ),
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Nenhuma meta definida. Defina metas para peso corporal, carga ou cárdio!',
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
              String unitLabel = 'kg';

              if (goal.tipo == 'peso') {
                currentVal = profile?.pesoAtual ?? 0.0;
                unitLabel = 'kg';
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
                    progress =
                        (initialVal - currentVal) /
                        (initialVal - goal.valorAlvo);
                  }
                } else {
                  // Ganho de peso
                  if (currentVal >= goal.valorAlvo) {
                    progress = 1.0;
                  } else if (currentVal <= initialVal) {
                    progress = 0.0;
                  } else {
                    progress =
                        (currentVal - initialVal) /
                        (goal.valorAlvo - initialVal);
                  }
                }
              } else if (goal.tipo == 'carga') {
                currentVal = maxLoads[goal.exercicioId] ?? 0.0;
                unitLabel = 'kg';
                final initialVal = goal.valorInicial ?? 0.0;
                if (currentVal >= goal.valorAlvo ||
                    initialVal >= goal.valorAlvo) {
                  progress = 1.0;
                } else if (currentVal <= initialVal) {
                  progress = 0.0;
                } else {
                  progress =
                      (currentVal - initialVal) / (goal.valorAlvo - initialVal);
                }
              } else if (goal.tipo == 'cardio_distancia') {
                currentVal = maxCardioDistance;
                unitLabel = 'km';
                final initialVal = goal.valorInicial ?? 0.0;
                if (currentVal >= goal.valorAlvo ||
                    initialVal >= goal.valorAlvo) {
                  progress = 1.0;
                } else if (currentVal <= initialVal) {
                  progress = 0.0;
                } else {
                  progress =
                      (currentVal - initialVal) / (goal.valorAlvo - initialVal);
                }
              } else if (goal.tipo == 'cardio_tempo') {
                currentVal = maxCardioDurationMin;
                unitLabel = 'min';
                final initialVal = goal.valorInicial ?? 0.0;
                if (currentVal >= goal.valorAlvo ||
                    initialVal >= goal.valorAlvo) {
                  progress = 1.0;
                } else if (currentVal <= initialVal) {
                  progress = 0.0;
                } else {
                  progress =
                      (currentVal - initialVal) / (goal.valorAlvo - initialVal);
                }
              }
              if (progress > 1.0) progress = 1.0;
              if (progress < 0.0) progress = 0.0;

              final isCompleted =
                  goal.concluido ||
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
                                  : AppColors.primaryLight.withValues(
                                      alpha: 0.6,
                                    ),
                              size: 22,
                            ),
                            onPressed: () => ref
                                .read(goalsProvider.notifier)
                                .toggleGoal(goal.id),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.tipo == 'peso'
                                      ? 'Meta de Peso Corporal'
                                      : goal.tipo == 'carga'
                                      ? 'Meta de Carga: ${goal.exercicioNome}'
                                      : goal.tipo == 'cardio_distancia'
                                      ? 'Meta de Distância Cárdio'
                                      : 'Meta de Duração Cárdio',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Criada em: ${goal.dataCriacao}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => ref
                                .read(goalsProvider.notifier)
                                .deleteGoal(goal.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Atual: ${currentVal.toStringAsFixed(1)} $unitLabel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Alvo: ${goal.valorAlvo.toStringAsFixed(1)} $unitLabel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
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
                          valueColor: AlwaysStoppedAnimation(
                            isCompleted
                                ? AppColors.success
                                : AppColors.primaryLight,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Meta Atingida! Parabéns! 🎉',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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

  void _showAddGoalDialog(
    BuildContext context,
    WidgetRef ref,
    double currentWeight,
    Map<int, double> maxLoads,
    List<Cardio> cardios,
  ) {
    String selectedType = 'peso';
    Exercise? selectedExercise;
    final valueController = TextEditingController();

    double maxCardioDistance = 0.0;
    double maxCardioDurationMin = 0.0;
    for (final c in cardios) {
      if (c.distanciaKm != null && c.distanciaKm! > maxCardioDistance) {
        maxCardioDistance = c.distanciaKm!;
      }
      final durationMin = c.duracaoSegundos / 60.0;
      if (durationMin > maxCardioDurationMin) {
        maxCardioDurationMin = durationMin;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
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
                  prefixIcon: Icon(
                    Icons.category_rounded,
                    color: context.onSurface,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'peso', child: Text('Peso Corporal')),
                  DropdownMenuItem(
                    value: 'carga',
                    child: Text('Carga de Exercício'),
                  ),
                  DropdownMenuItem(
                    value: 'cardio_distancia',
                    child: Text('Distância de Cárdio (Sessão)'),
                  ),
                  DropdownMenuItem(
                    value: 'cardio_tempo',
                    child: Text('Duração de Cárdio (Sessão)'),
                  ),
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
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cadastre exercícios para definir metas de carga.',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<Exercise>(
                    initialValue: exercises.contains(selectedExercise)
                        ? selectedExercise
                        : null,
                    dropdownColor: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      labelText: 'Selecione o Exercício',
                      labelStyle: TextStyle(
                        color: context.onSurface,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      prefixIcon: Icon(
                        Icons.fitness_center_rounded,
                        color: context.onSurface,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.divider,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [DecimalInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Valor Alvo',
                  labelStyle: TextStyle(color: context.onSurface, fontSize: 13),
                  hintText: selectedType == 'cardio_distancia'
                      ? '10.0'
                      : selectedType == 'cardio_tempo'
                      ? '45.0'
                      : '80.0',
                  suffixText: selectedType == 'cardio_distancia'
                      ? 'km'
                      : selectedType == 'cardio_tempo'
                      ? 'min'
                      : 'kg',
                  suffixStyle: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  prefixIcon: Icon(
                    Icons.ads_click_rounded,
                    color: context.onSurface,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: context.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final target = double.tryParse(
                  valueController.text.replaceAll(',', '.'),
                );
                if (target == null || target <= 0) return;

                if (selectedType == 'carga' && selectedExercise == null) return;

                final nowStr =
                    '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';

                final initialVal = selectedType == 'peso'
                    ? currentWeight
                    : selectedType == 'carga'
                    ? (maxLoads[selectedExercise!.id] ?? 0.0)
                    : selectedType == 'cardio_distancia'
                    ? maxCardioDistance
                    : maxCardioDurationMin;

                final newGoal = Goal(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  tipo: selectedType,
                  exercicioId: selectedType == 'carga'
                      ? selectedExercise!.id
                      : null,
                  exercicioNome: selectedType == 'carga'
                      ? selectedExercise!.nome
                      : null,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
