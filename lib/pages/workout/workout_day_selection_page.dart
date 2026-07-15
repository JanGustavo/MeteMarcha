// lib/pages/workout/workout_day_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../setup/split_selection_page.dart';
import '../../core/utils/premium_page_route.dart';
import 'workout_page.dart';

class WorkoutDaySelectionPage extends ConsumerWidget {
  const WorkoutDaySelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplit = ref.watch(activeSplitProvider);
    final splitDays = ref.watch(activeSplitDaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Qual treino hoje?')),
      body: activeSplit.when(
        data: (split) {
          if (split == null) {
            return _NoSplitHint(onConfigure: () {
              Navigator.pushReplacement(
                context,
                PremiumPageRoute(
                  page: const SplitSelectionPage(),
                  transitionType: TransitionType.slideRight,
                ),
              );
            });
          }

          return splitDays.when(
            data: (days) {
              if (days.isEmpty) {
                return const Center(child: Text('Nenhum dia configurado.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: days.length,
                itemBuilder: (_, i) => _DayCard(day: days[i]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  final WorkoutDay day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          // Verificar se já tem sessão em andamento para este dia
          final workoutDao = ref.read(workoutDaoProvider);
          final existing = await workoutDao.getActiveSession();

          if (!context.mounted) return;

          if (existing != null && existing.dayId == day.id) {
            // Retoma sessão em andamento
            Navigator.push(
              context,
              PremiumPageRoute(
                page: WorkoutPage(
                  dayId: day.id,
                  dayName: day.nome,
                  sessionId: existing.id,
                ),
                transitionType: TransitionType.slideRight,
              ),
            );
            return;
          }

          if (existing != null) {
            // Tem sessão de outro dia — pergunta o que fazer
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Treino em andamento'),
                content: const Text(
                  'Já existe um treino em andamento. '
                  'Deseja cancelá-lo e iniciar um novo?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Não'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sim, cancelar'),
                  ),
                ],
              ),
            );
            if (ok != true || !context.mounted) return;
            await workoutDao.cancelSession(existing.id);
          }

          // Cria nova sessão
          final sessionId = await workoutDao.insertSession(
            WorkoutSessionsCompanion.insert(
              dayId: Value(day.id),
              data: DateTime.now().toIso8601String(),
            ),
          );

          if (!context.mounted) return;
          Navigator.push(
            context,
            PremiumPageRoute(
              page: WorkoutPage(
                dayId: day.id,
                dayName: day.nome,
                sessionId: sessionId,
              ),
              transitionType: TransitionType.slideRight,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Letra do dia
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.getWorkoutColor(day.letra),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  day.letra,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treino ${day.letra}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                             color: AppColors.getWorkoutColor(day.letra),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSplitHint extends StatelessWidget {
  final VoidCallback onConfigure;
  const _NoSplitHint({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_rounded,
                size: 48, color: AppColors.divider),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma divisão configurada.\nEscolha uma divisão para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurface),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onConfigure,
              child: const Text('Configurar divisão'),
            ),
          ],
        ),
      ),
    );
  }
}
