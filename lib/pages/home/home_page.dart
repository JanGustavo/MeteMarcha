// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';
import '../../widgets/weekly_weight_banner.dart';
import '../../widgets/weekly_schedule_banner.dart';
import '../profile/profile_page.dart';
import '../progress/progress_page.dart';
import '../setup/setup_page.dart';
import '../setup/split_selection_page.dart';
import '../workout/workout_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final splitsAsync = ref.watch(splitsProvider);

    return splitsAsync.when(
      data: (splits) {
        if (splits.isEmpty) {
          return const SplitSelectionPage(isOnboarding: true);
        }
        return Scaffold(
          body: IndexedStack(
            index: _currentTab,
            children: const [
              _TreinoTab(),
              ProgressPage(),
              ProfilePage(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_rounded),
                label: 'Treino',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Progresso',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erro ao carregar treinos: $e')),
      ),
    );
  }
}

// ─── ABA DE TREINOS (DASHBOARD) ──────────────────────────────────────────────────

class _TreinoTab extends ConsumerWidget {
  const _TreinoTab();

  void _confirmDeleteSplit(BuildContext context, WidgetRef ref, WorkoutSplit split) {
    final displayName = split.nome.isNotEmpty ? split.nome : split.tipo;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir treino?'),
        content: Text(
          'Deseja excluir permanentemente a rotina "$displayName" e todo o histórico de execuções vinculado a ela?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(workoutDaoProvider).deleteSplit(split.id);
              ref.invalidate(splitsProvider);
              ref.invalidate(activeSplitProvider);
              ref.invalidate(activeSplitDaysProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _renameSplitDialog(BuildContext context, WidgetRef ref, WorkoutSplit split) {
    final controller = TextEditingController(text: split.nome.isNotEmpty ? split.nome : split.tipo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Renomear Treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do Treino',
            hintText: 'Ex: Treino V-Shape',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final db = ref.read(databaseProvider);
              await (db.update(db.workoutSplits)..where((s) => s.id.equals(split.id))).write(
                WorkoutSplitsCompanion(nome: Value(newName)),
              );

              ref.invalidate(splitsProvider);
              ref.invalidate(activeSplitProvider);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showSplitOptions(BuildContext context, WidgetRef ref, WorkoutSplit split) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                split.nome.isNotEmpty ? split.nome : split.tipo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Divisão do tipo: ${split.tipo}',
                style: const TextStyle(color: AppColors.onSurface, fontSize: 12),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.primaryLight),
                title: const Text('Renomear Treino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameSplitDialog(context, ref, split);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.primary),
                title: const Text('Excluir Treino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteSplit(context, ref, split);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightRegisteredAsync = ref.watch(weeklyWeightRegisteredProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);
    final activeSplitAsync = ref.watch(activeSplitProvider);
    final splitsAsync = ref.watch(splitsProvider);
    final daysAsync = ref.watch(activeSplitDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeteMacha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurar Treinos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SetupPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Recarrega dados reativos invalidando os providers
          ref.invalidate(weeklyWeightRegisteredProvider);
          ref.invalidate(activeSessionProvider);
          ref.invalidate(activeSplitProvider);
          ref.invalidate(splitsProvider);
          ref.invalidate(activeSplitDaysProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Planejamento Semanal (Notificações) ────────────────────
            const WeeklyScheduleBanner(),

            // ── Banner de peso corporal ────────────────────────────────
            weightRegisteredAsync.when(
              data: (registered) => registered
                  ? const SizedBox.shrink()
                  : const WeeklyWeightBanner(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Sessão Ativa / Em Andamento ────────────────────────────
            activeSessionAsync.when(
              data: (session) {
                if (session == null) return const SizedBox.shrink();
                return _ActiveSessionCard(session: session);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Seleção de Divisão (Split) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SUA DIVISÃO',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '(Segure para opções)',
                        style: TextStyle(
                          color: AppColors.onSurface.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  splitsAsync.when(
                    data: (splits) {
                      final activeSplit = activeSplitAsync.value;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...splits.map((split) {
                            final isSelected = activeSplit?.id == split.id;
                            return GestureDetector(
                              onLongPress: () => _showSplitOptions(context, ref, split),
                              child: ChoiceChip(
                                label: Text(split.nome.isNotEmpty ? split.nome : split.tipo),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    ref
                                        .read(workoutDaoProvider)
                                        .setActiveSplit(split.id);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                          ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                            label: const Text(
                              'ADICIONAR',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SplitSelectionPage(isOnboarding: false),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Erro ao carregar divisões: $e'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // ── Dias de treino da divisão ativa ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DIAS DE TREINO',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetupPage()),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                    label: const Text(
                      'CONFIGURAR',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            daysAsync.when(
              data: (days) {
                if (days.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhum dia cadastrado para esta divisão.\nUse o botão de ajuste acima para configurar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.onSurface),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  itemBuilder: (_, index) {
                    final day = days[index];
                    return _DayListTile(day: day);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro ao carregar dias: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARD DE SESSÃO ATIVA ────────────────────────────────────────────────────────

class _ActiveSessionCard extends ConsumerWidget {
  final WorkoutSession session;
  const _ActiveSessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WorkoutDay?>(
      future: ref.read(workoutDaoProvider).getDayById(session.dayId),
      builder: (context, snapshot) {
        final day = snapshot.data;
        final name = day != null ? 'Dia ${day.letra} - ${day.nome}' : 'Treino';

        return Card(
          color: AppColors.primaryDark.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'TREINO EM ANDAMENTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Iniciado em: ${WeekUtils.formatDate(session.data)}',
                  style:
                      const TextStyle(color: AppColors.onSurface, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _confirmCancel(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                      ),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WorkoutPage(
                              dayId: session.dayId,
                              dayName: name,
                              sessionId: session.id,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('RETOMAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cancelar treino?'),
        content: const Text(
          'Tem certeza que deseja cancelar esta sessão? Todos os logs registrados hoje serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(workoutDaoProvider).deleteSession(session.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Cancelar Treino'),
          ),
        ],
      ),
    );
  }
}

// ─── LIST TILE DO DIA DE TREINO ──────────────────────────────────────────────────

class _DayListTile extends ConsumerWidget {
  final WorkoutDay day;
  const _DayListTile({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Exercise>>(
      future: ref.read(exerciseDaoProvider).getExercisesForDay(day.id),
      builder: (context, snapshot) {
        final exercises = snapshot.data ?? [];
        final preview = exercises.isEmpty
            ? 'Nenhum exercício configurado.'
            : exercises.map((e) => e.nome).join(', ');

        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.getWorkoutColor(day.letra),
              foregroundColor: Colors.white,
              child: Text(
                day.letra,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              'Dia ${day.letra} - ${day.nome}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _showDayExercises(context, ref, exercises),
          ),
        );
      },
    );
  }

  void _showDayExercises(
      BuildContext context, WidgetRef ref, List<Exercise> exercises) {
    final dayName = 'Dia ${day.letra} - ${day.nome}';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetupPage()),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                    label: const Text(
                      'EDITAR',
                      style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Sem exercícios cadastrados neste dia.',
                      style: TextStyle(color: AppColors.onSurface),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: exercises.length,
                    itemBuilder: (_, idx) {
                      final ex = exercises[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.circle,
                                size: 6, color: AppColors.getWorkoutColor(day.letra)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ex.nome,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '${ex.grupoMuscular} \u00b7 ${ex.equipamento}${ex.volume != null && ex.volume!.isNotEmpty ? ' \u00b7 ${ex.volume}' : ''}',
                              style: const TextStyle(
                                  color: AppColors.onSurface, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getWorkoutColor(day.letra),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: exercises.isEmpty
                      ? null
                      : () async {
                          // Fecha o bottom sheet
                          Navigator.pop(ctx);

                          // Verifica se já existe uma sessão ativa
                          final active = await ref
                              .read(workoutDaoProvider)
                              .getActiveSession();
                          if (active != null) {
                            // ignore: use_build_context_synchronously
                            _showActiveConflictDialog(context, ref, active);
                            return;
                          }

                          // Cria uma nova sessão de treino
                          final sessionId = await ref
                              .read(workoutDaoProvider)
                              .insertSession(
                                WorkoutSessionsCompanion.insert(
                                  dayId: day.id,
                                  data: DateTime.now().toIso8601String(),
                                  status: const Value('em_andamento'),
                                ),
                              );

                          // Abre o treino
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkoutPage(
                                dayId: day.id,
                                dayName: dayName,
                                sessionId: sessionId,
                              ),
                            ),
                          );
                        },
                  child: const Text('INICIAR TREINO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveConflictDialog(
      BuildContext context, WidgetRef ref, WorkoutSession active) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Treino em andamento'),
        content: const Text(
          'Já existe uma sessão de treino iniciada. Deseja cancelá-la para iniciar este novo treino ou prefere retomá-la?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              // Cancela treino anterior e fecha dialog
              await ref.read(workoutDaoProvider).deleteSession(active.id);
              if (ctx.mounted) Navigator.pop(ctx);
              // Inicia novo treino
              final sessionId = await ref.read(workoutDaoProvider).insertSession(
                    WorkoutSessionsCompanion.insert(
                      dayId: day.id,
                      data: DateTime.now().toIso8601String(),
                      status: const Value('em_andamento'),
                    ),
                  );
              // ignore: use_build_context_synchronously
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutPage(
                      dayId: day.id,
                      dayName: 'Dia ${day.letra} - ${day.nome}',
                      sessionId: sessionId,
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
            child: const Text('CANCELAR ANTERIOR'),
          ),
        ],
      ),
    );
  }
}
