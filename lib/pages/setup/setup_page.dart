// lib/pages/setup/setup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/constants/equipment_options.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class SetupPage extends ConsumerStatefulWidget {
  final int initialTab;
  const SetupPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFIGURAR APP'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.onSurface,
          tabs: const [
            Tab(text: 'Exercícios', icon: Icon(Icons.fitness_center_rounded)),
            Tab(text: 'Meus Treinos', icon: Icon(Icons.calendar_month_rounded)),
            Tab(text: 'Rotina Semanal', icon: Icon(Icons.view_week_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExercisesSetupTab(),
          _RoutineSetupTab(),
          _WeeklyScheduleTab(),
        ],
      ),
    );
  }
}

// \u2500\u2500\u2500 ABA DE GERENCIAMENTO DE EXERC\u00cdCIOS \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

class _ExercisesSetupTab extends ConsumerWidget {
  const _ExercisesSetupTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(allExercisesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseSheet(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Nenhum exerc\u00edcio cadastrado.',
                    style: TextStyle(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExerciseSheet(context, ref),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('CRIAR MEU PRIMEIRO EXERC\u00cdCIO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Agrupa por grupo muscular
          final grouped = <String, List<Exercise>>{};
          for (final ex in exercises) {
            grouped.putIfAbsent(ex.grupoMuscular, () => []).add(ex);
          }

          final groups = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: groups.length,
            itemBuilder: (_, index) {
              final group = groups[index];
              final list = grouped[group]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      group.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...list.map((ex) => Card(
                        child: ListTile(
                          onTap: () =>
                              _showAddExerciseSheet(context, ref, exercise: ex),
                          title: Text(ex.nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ex.equipamento}${ex.volume != null && ex.volume!.isNotEmpty ? ' \u00b7 ${ex.volume}' : ''} \u00b7 ${ex.tempoDescansoSegundos}s descanso${ex.isUnilateral ? ' \u00b7 Unilateral' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.onSurface),
                              ),
                              if (ex.link != null && ex.link!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _openLink(ex.link!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.link_rounded,
                                          size: 12,
                                          color: AppColors.primaryLight),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          ex.link!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryLight,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.primaryLight, size: 20),
                                onPressed: () => _showAddExerciseSheet(
                                    context, ref,
                                    exercise: ex),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.primaryLight, size: 20),
                                onPressed: () =>
                                    _confirmDelete(context, ref, ex),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Exercise ex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir exerc\u00edcio?'),
        content: Text(
          'Deseja excluir "${ex.nome}"? Se ele estiver associado a algum dia de treino ou log, a opera\u00e7\u00e3o falhar\u00e1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(exerciseDaoProvider).deleteExercise(ex.id);
                ref.invalidate(allExercisesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Falha: O exerc\u00edcio est\u00e1 em uso na rotina ou nos hist\u00f3ricos.',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// \u2500\u2500\u2500 ABA DE GERENCIAMENTO DE ROTINAS \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

class _RoutineSetupTab extends ConsumerStatefulWidget {
  const _RoutineSetupTab();

  @override
  ConsumerState<_RoutineSetupTab> createState() => _RoutineSetupTabState();
}

class _RoutineSetupTabState extends ConsumerState<_RoutineSetupTab> {
  WorkoutDay? _selectedDay;

  void _editDay(BuildContext context, WorkoutDay day) {
    final letraCtrl = TextEditingController(text: day.letra);
    final nomeCtrl = TextEditingController(text: day.nome);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Editar Dia de Treino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: letraCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Letra (ex: A, B, C)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome / Músculos (ex: Peito e Tríceps)',
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
            onPressed: () async {
              final letra = letraCtrl.text.trim().toUpperCase();
              final nome = nomeCtrl.text.trim();
              if (letra.isEmpty || nome.isEmpty) return;

              final updatedDay = day.copyWith(letra: letra, nome: nome);
              await ref.read(workoutDaoProvider).updateDay(updatedDay);
              
              ref.invalidate(activeSplitDaysProvider);
              
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {
                _selectedDay = updatedDay;
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _addDay(BuildContext context, int splitId, List<WorkoutDay> existingDays) {
    String nextLetter = 'A';
    if (existingDays.isNotEmpty) {
      final lastLetter = existingDays.last.letra;
      if (lastLetter.isNotEmpty) {
        final lastLetterCode = lastLetter.codeUnitAt(0);
        if (lastLetterCode >= 65 && lastLetterCode < 90) {
          nextLetter = String.fromCharCode(lastLetterCode + 1);
        } else if (lastLetterCode >= 97 && lastLetterCode < 122) {
          nextLetter = String.fromCharCode(lastLetterCode + 1).toUpperCase();
        }
      }
    }
    final letraCtrl = TextEditingController(text: nextLetter);
    final nomeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Adicionar Dia de Treino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: letraCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Letra (ex: A, B, C)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome / Músculos (ex: Perna Completa)',
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
            onPressed: () async {
              final letra = letraCtrl.text.trim().toUpperCase();
              final nome = nomeCtrl.text.trim();
              if (letra.isEmpty || nome.isEmpty) return;

              await ref.read(workoutDaoProvider).insertDay(
                WorkoutDaysCompanion.insert(
                  splitId: splitId,
                  letra: letra,
                  nome: nome,
                ),
              );

              ref.invalidate(activeSplitDaysProvider);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _deleteDay(BuildContext context, WorkoutDay day, List<WorkoutDay> allDays) {
    if (allDays.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A divisão precisa ter pelo menos 1 dia de treino.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir Dia de Treino?'),
        content: Text(
          'Deseja excluir permanentemente o "Dia ${day.letra} - ${day.nome}"? '
          'Todos os históricos de treinos executados neste dia serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final dayId = day.id;
              await ref.read(workoutDaoProvider).transaction(() async {
                final db = ref.read(databaseProvider);
                await (db.update(db.weeklySchedules)..where((s) => s.dayId.equals(dayId))).write(
                  const WeeklySchedulesCompanion(dayId: Value(null)),
                );
                await (db.delete(db.workoutDayExercises)..where((de) => de.dayId.equals(dayId))).go();
                final sessions = await (db.select(db.workoutSessions)..where((s) => s.dayId.equals(dayId))).get();
                for (final session in sessions) {
                  await (db.delete(db.exerciseLogs)..where((l) => l.sessionId.equals(session.id))).go();
                  await (db.delete(db.workoutSessions)..where((s) => s.id.equals(session.id))).go();
                }
                await (db.delete(db.workoutDays)..where((d) => d.id.equals(dayId))).go();
              });

              ref.invalidate(activeSplitDaysProvider);

              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {
                _selectedDay = null;
              });
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(activeSplitDaysProvider);

    return Scaffold(
      body: daysAsync.when(
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum dia de treino cadastrado na divisão ativa.',
                style: TextStyle(color: AppColors.onSurface),
              ),
            );
          }

          if (_selectedDay == null) {
            _selectedDay = days.first;
          } else {
            final idx = days.indexWhere((d) => d.id == _selectedDay!.id);
            if (idx != -1) {
              _selectedDay = days[idx];
            } else {
              _selectedDay = days.first;
            }
          }

          return Column(
            children: [
              // Seletor de dia
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selecionar Dia:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: AppColors.primaryLight, size: 20),
                              tooltip: 'Editar Dia',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              onPressed: () => _editDay(context, _selectedDay!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  color: AppColors.primaryLight, size: 20),
                              tooltip: 'Adicionar Dia',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              onPressed: () =>
                                  _addDay(context, _selectedDay!.splitId, days),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.primaryLight, size: 20),
                              tooltip: 'Excluir Dia',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              onPressed: () =>
                                  _deleteDay(context, _selectedDay!, days),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<WorkoutDay>(
                      value: _selectedDay,
                      dropdownColor: AppColors.card,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: days
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  'Dia ${d.letra} - ${d.nome}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (d) => setState(() => _selectedDay = d),
                    ),
                  ],
                ),
              ),

              // Lista de exerc\u00edcios vinculados ao dia selecionado
              Expanded(
                child: _RoutineExercisesList(day: _selectedDay!),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _RoutineExercisesList extends ConsumerStatefulWidget {
  final WorkoutDay day;
  const _RoutineExercisesList({required this.day});

  @override
  ConsumerState<_RoutineExercisesList> createState() =>
      _RoutineExercisesListState();
}

class _RoutineExercisesListState extends ConsumerState<_RoutineExercisesList> {
  List<Exercise> _exercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _RoutineExercisesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day.id != widget.day.id) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list =
        await ref.read(exerciseDaoProvider).getExercisesForDay(widget.day.id);
    setState(() {
      _exercises = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExerciseToDay(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _exercises.isEmpty
          ? const Center(
              child: Text(
                'Nenhum exerc\u00edcio vinculado a este dia.',
                style: TextStyle(color: AppColors.onSurface),
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Arraste e solte para reordenar os exerc\u00edcios do treino (toque para editar)',
                    style: TextStyle(fontSize: 11, color: AppColors.onSurface),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final ex = _exercises[index];
                      return Card(
                        key: ValueKey(ex.id),
                        child: ListTile(
                          onTap: () => _showAddExerciseSheet(
                            context,
                            ref,
                            exercise: ex,
                            onSaved: (_) => _load(),
                          ),
                          leading: const Icon(Icons.drag_handle_rounded,
                              color: AppColors.onSurface),
                          title: Text(ex.nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ex.grupoMuscular} \u00b7 ${ex.equipamento}${ex.volume != null && ex.volume!.isNotEmpty ? ' \u00b7 ${ex.volume}' : ''} \u00b7 ${ex.tempoDescansoSegundos}s descanso${ex.isUnilateral ? ' \u00b7 Unilateral' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.onSurface),
                              ),
                              if (ex.link != null && ex.link!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _openLink(ex.link!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.link_rounded,
                                          size: 12,
                                          color: AppColors.primaryLight),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          ex.link!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryLight,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.primaryLight, size: 20),
                                onPressed: () => _showAddExerciseSheet(
                                  context,
                                  ref,
                                  exercise: ex,
                                  onSaved: (_) => _load(),
                                ),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.link_off_rounded,
                                    color: AppColors.primaryLight, size: 20),
                                onPressed: () => _unlink(ex),
                                tooltip: 'Desvincular',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onReorder: _reorder,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _unlink(Exercise ex) async {
    await ref
        .read(exerciseDaoProvider)
        .unlinkExerciseFromDay(widget.day.id, ex.id);
    _load();
    ref.invalidate(activeSplitDaysProvider);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });

    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      await (db.delete(db.workoutDayExercises)
            ..where((de) => de.dayId.equals(widget.day.id)))
          .go();

      for (var i = 0; i < _exercises.length; i++) {
        await db.into(db.workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(
                dayId: widget.day.id,
                exerciseId: _exercises[i].id,
                ordem: i,
              ),
            );
      }
    });

    ref.invalidate(activeSplitDaysProvider);
  }

  void _showCreateAndLinkSheet(BuildContext context) {
    _showAddExerciseSheet(
      context,
      ref,
      onSaved: (newExerciseId) async {
        await ref.read(exerciseDaoProvider).linkExerciseToDay(
              WorkoutDayExercisesCompanion.insert(
                dayId: widget.day.id,
                exerciseId: newExerciseId,
                ordem: _exercises.length,
              ),
            );
        ref.invalidate(activeSplitDaysProvider);
        _load();
      },
    );
  }

  void _addExerciseToDay(BuildContext context) async {
    final allExs = await ref.read(exerciseDaoProvider).getAll();
    final linkedIds = _exercises.map((e) => e.id).toSet();
    final unlinked = allExs.where((e) => !linkedIds.contains(e.id)).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Vincular Exerc\u00edcio'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unlinked.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Todos os exerc\u00edcios cadastrados j\u00e1 fazem parte deste dia de treino.',
                    style: TextStyle(color: AppColors.onSurface),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: unlinked.length,
                    itemBuilder: (_, index) {
                      final ex = unlinked[index];
                      return ListTile(
                        title: Text(ex.nome,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${ex.grupoMuscular} \u00b7 ${ex.equipamento}${ex.volume != null && ex.volume!.isNotEmpty ? ' \u00b7 ${ex.volume}' : ''}'),
                        trailing: ex.link != null
                            ? const Icon(Icons.play_circle_fill_rounded,
                                color: AppColors.warning, size: 20)
                            : null,
                        onTap: () async {
                          await ref.read(exerciseDaoProvider).linkExerciseToDay(
                                WorkoutDayExercisesCompanion.insert(
                                  dayId: widget.day.id,
                                  exerciseId: ex.id,
                                  ordem: _exercises.length,
                                ),
                              );
                          ref.invalidate(activeSplitDaysProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        },
                      );
                    },
                  ),
                ),
              const Divider(color: AppColors.divider),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCreateAndLinkSheet(context);
                },
                icon: const Icon(Icons.add, color: AppColors.primaryLight),
                label: const Text(
                  'CRIAR NOVO E VINCULAR',
                  style: TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

// \u2500\u2500\u2500 DIALOG DE CADASTRO/EDI\u00c7\u00c3O DE EXERC\u00cdCIO \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

void _showAddExerciseSheet(
  BuildContext context,
  WidgetRef ref, {
  Exercise? exercise,
  void Function(int)? onSaved,
}) {
  final nameCtrl = TextEditingController(text: exercise?.nome ?? '');
  final restCtrl = TextEditingController(
      text: exercise?.tempoDescansoSegundos.toString() ?? '90');
  final linkCtrl = TextEditingController(text: exercise?.link ?? '');
  final volumeCtrl = TextEditingController(text: exercise?.volume ?? '');
  String group = exercise?.grupoMuscular ?? 'Peito';
  String equipment = exercise?.equipamento ?? 'Livre';
  bool unilateral = exercise?.isUnilateral ?? false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise == null
                    ? 'Novo Exerc\u00edcio'
                    : 'Editar Exerc\u00edcio',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: exercise == null,
                decoration:
                    const InputDecoration(labelText: 'Nome do Exerc\u00edcio'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: group,
                      decoration:
                          const InputDecoration(labelText: 'Grupo Muscular'),
                      dropdownColor: AppColors.card,
                      items: [
                        'Peito',
                        'Costas',
                        'Ombro',
                        'Tr\u00edceps',
                        'B\u00edceps',
                        'Perna',
                        'Core',
                        'Gl\u00fateo'
                      ]
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setModalState(() => group = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: equipment,
                      decoration:
                          const InputDecoration(labelText: 'Equipamento'),
                      dropdownColor: AppColors.card,
                      items: equipmentOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => equipment = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link de Execu\u00e7\u00e3o (YouTube/etc)',
                  hintText: 'https://youtube.com/...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: volumeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Volume Alvo (ex: 3x12)',
                  hintText: '3x12',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: restCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Descanso (segundos)'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text('Unilateral:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Switch(
                    value: unilateral,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setModalState(() => unilateral = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final rest = int.tryParse(restCtrl.text) ?? 90;
                    final link = linkCtrl.text.trim();
                    final linkVal = link.isEmpty ? null : link;
                    final volume = volumeCtrl.text.trim();
                    final volumeVal = volume.isEmpty ? null : volume;
                    if (name.isEmpty) return;

                    int savedId;
                    if (exercise == null) {
                      savedId =
                          await ref.read(exerciseDaoProvider).insertExercise(
                                ExercisesCompanion.insert(
                                  nome: name,
                                  grupoMuscular: group,
                                  equipamento: Value(equipment),
                                  isUnilateral: Value(unilateral),
                                  tempoDescansoSegundos: Value(rest),
                                  link: Value(linkVal),
                                  volume: Value(volumeVal),
                                  vezesFeito: const Value(0),
                                ),
                              );
                    } else {
                      await ref.read(exerciseDaoProvider).updateExercise(
                            Exercise(
                              id: exercise.id,
                              nome: name,
                              grupoMuscular: group,
                              equipamento: equipment,
                              isUnilateral: unilateral,
                              tempoDescansoSegundos: rest,
                              link: linkVal,
                              volume: volumeVal,
                              vezesFeito: exercise.vezesFeito,
                            ),
                          );
                      savedId = exercise.id;
                    }

                    ref.invalidate(allExercisesProvider);
                    if (onSaved != null) {
                      onSaved(savedId);
                    }

                    // ignore: use_build_context_synchronously
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(exercise == null
                      ? 'SALVAR EXERC\u00cdCIO'
                      : 'SALVAR ALTERA\u00c7\u00d5ES'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// \u2500\u2500\u2500 AUXILIAR PARA ABRIR LINKS \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

Future<void> _openLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Falha silenciosa ou log
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB DE PLANEJAMENTO SEMANAL (KANBAN / PAREAMENTO)
// ═══════════════════════════════════════════════════════════════════

class _WeeklyScheduleTab extends ConsumerStatefulWidget {
  const _WeeklyScheduleTab();

  @override
  ConsumerState<_WeeklyScheduleTab> createState() => _WeeklyScheduleTabState();
}

class _WeeklyScheduleTabState extends ConsumerState<_WeeklyScheduleTab> {
  int? _selectedWorkoutDayId; // null = none, -1 = rest, positive = workout day id

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(weeklyScheduleProvider);
    final daysAsync = ref.watch(activeSplitDaysProvider);
    final splitAsync = ref.watch(activeSplitProvider);

    return splitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro ao carregar: $err')),
      data: (activeSplit) {
        if (activeSplit == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 64, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma Rotina Ativa',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ative uma rotina na aba "Minhas Rotinas" para configurar seu planejamento semanal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          );
        }

        return daysAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Erro ao carregar dias: $err')),
          data: (workoutDays) {
            return scheduleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Erro ao carregar agenda: $err')),
              data: (schedules) {
                // Se schedules estiver vazio, tenta inicializar
                if (schedules.isEmpty) {
                  ref.read(workoutDaoProvider).seedWeeklySchedule();
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLANEJAMENTO SEMANAL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque em um treino abaixo para selecioná-lo e depois toque nos dias da semana para vinculá-lo rapidamente, ou use arrastar e soltar.',
                        style:
                            TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // ── Draggable & Selectable Workouts Row ──
                      const Text(
                        'Treinos Disponíveis',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          // Descanso Draggable/Selectable
                          _buildDraggableItem(
                            context: context,
                            label: 'Descanso 💧',
                            id: -1,
                            color: Colors.grey.shade700,
                          ),
                          // Workout Days
                          ...workoutDays.map((day) {
                            return _buildDraggableItem(
                              context: context,
                              label: 'Treino ${day.letra}: ${day.nome}',
                              id: day.id,
                              color: AppColors.getWorkoutColor(day.letra),
                            );
                          }),
                        ],
                      ),

                      if (_selectedWorkoutDayId != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedWorkoutDayId == -1
                                      ? 'Modo Seleção Rápida: Toque em qualquer dia abaixo para defini-lo como Descanso.'
                                      : 'Modo Seleção Rápida: Toque nos dias abaixo para vincular o treino selecionado.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _selectedWorkoutDayId = null),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── Weekly Schedule Grid/List ──
                      const Text(
                        'Agenda da Semana',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          final assignedDay = workoutDays.firstWhere(
                            (d) => d.id == schedule.dayId,
                            orElse: () => const WorkoutDay(
                                id: -1, splitId: -1, letra: '', nome: ''),
                          );
                          final hasWorkout = assignedDay.id != -1;

                          return Padding(
                            key: ValueKey(schedule.id),
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: DragTarget<int>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) async {
                                final selectedId =
                                    details.data == -1 ? null : details.data;
                                await ref
                                    .read(workoutDaoProvider)
                                    .updateWeeklyDay(
                                      schedule.id,
                                      selectedId,
                                    );
                              },
                              builder: (context, candidateData, rejectedData) {
                                final isHovered = candidateData.isNotEmpty;
                                return GestureDetector(
                                  onTap: () async {
                                    if (_selectedWorkoutDayId != null) {
                                      final selectedId = _selectedWorkoutDayId == -1
                                          ? null
                                          : _selectedWorkoutDayId;
                                      await ref
                                          .read(workoutDaoProvider)
                                          .updateWeeklyDay(
                                            schedule.id,
                                            selectedId,
                                          );
                                    } else {
                                      _showDayAssignmentPicker(
                                        context,
                                        schedule,
                                        workoutDays,
                                      );
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? AppColors.primary.withOpacity(0.15)
                                          : AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isHovered
                                            ? AppColors.primary
                                            : (hasWorkout
                                                ? AppColors.getWorkoutColor(
                                                        assignedDay.letra)
                                                    .withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.2)),
                                        width: isHovered ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Dia da Semana
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                schedule.diaSemana,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.onBackground,
                                                ),
                                              ),
                                              if (isHovered)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    'Solte para parear',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .primaryLight,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Treino Pareado ou Descanso
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (hasWorkout) ...[
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                              .getWorkoutColor(
                                                                  assignedDay
                                                                      .letra)
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: AppColors
                                                                  .getWorkoutColor(
                                                                      assignedDay
                                                                          .letra)
                                                              .withOpacity(
                                                                  0.4)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .fitness_center_rounded,
                                                            size: 14,
                                                            color: AppColors
                                                                .getWorkoutColor(
                                                                    assignedDay
                                                                        .letra)),
                                                        const SizedBox(
                                                            width: 6),
                                                        Flexible(
                                                          child: Text(
                                                            'Treino ${assignedDay.letra}: ${assignedDay.nome}',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .getWorkoutColor(
                                                                      assignedDay
                                                                          .letra),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.clear,
                                                      size: 18,
                                                      color: Colors.grey),
                                                  onPressed: () async {
                                                    await ref
                                                        .read(
                                                            workoutDaoProvider)
                                                        .updateWeeklyDay(
                                                          schedule.id,
                                                          null,
                                                        );
                                                  },
                                                ),
                                              ] else ...[
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .nightlight_round,
                                                          size: 14,
                                                          color: Colors.grey),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Descanso 💧',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableItem({
    required BuildContext context,
    required String label,
    required int id,
    required Color color,
  }) {
    final isSelected = _selectedWorkoutDayId == id;
    
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 48,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? color.withOpacity(0.6) : color.withOpacity(0.3),
            blurRadius: isSelected ? 10 : 6,
            spreadRadius: isSelected ? 1 : 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(
              id == -1 ? Icons.nightlight_round : Icons.fitness_center_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedWorkoutDayId == id) {
            _selectedWorkoutDayId = null;
          } else {
            _selectedWorkoutDayId = id;
          }
        });
      },
      child: Draggable<int>(
        data: id,
        feedback: Opacity(
          opacity: 0.8,
          child: Material(
            color: Colors.transparent,
            child: chip,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: chip,
        ),
        child: chip,
      ),
    );
  }

  void _showDayAssignmentPicker(
    BuildContext context,
    WeeklySchedule schedule,
    List<WorkoutDay> workoutDays,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parear dia: ${schedule.diaSemana}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 16),

                // Opção de Descanso
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.nightlight_round, color: Colors.white),
                  ),
                  title: const Text('Descanso / Folga',
                      style: TextStyle(color: AppColors.onBackground)),
                  subtitle: const Text(
                      'Dia focado em recuperação e hidratação 💧',
                      style:
                          TextStyle(color: AppColors.onSurface, fontSize: 12)),
                  trailing: schedule.dayId == null
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    await ref
                        .read(workoutDaoProvider)
                        .updateWeeklyDay(schedule.id, null);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const Divider(color: Colors.grey),

                // Lista de Treinos
                ...workoutDays.map((day) {
                  final isSelected = schedule.dayId == day.id;
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.fitness_center_rounded,
                          color: Colors.white),
                    ),
                    title: Text('Treino ${day.letra}',
                        style: const TextStyle(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(day.nome,
                        style: const TextStyle(
                            color: AppColors.onSurface, fontSize: 12)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () async {
                      await ref
                          .read(workoutDaoProvider)
                          .updateWeeklyDay(schedule.id, day.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
