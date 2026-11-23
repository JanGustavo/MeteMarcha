import '../../core/media/reference_video_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/training_focus_provider.dart';
import '../../core/services/squad_service.dart';
import '../home/home_page.dart';

class MiniWorkoutPage extends ConsumerStatefulWidget {
  const MiniWorkoutPage(
      {super.key, this.onboarding = false, this.focus, this.api});
  final bool onboarding;
  final String? focus;
  final SquadService? api;
  @override
  ConsumerState<MiniWorkoutPage> createState() => _MiniWorkoutPageState();
}

class _MiniWorkoutPageState extends ConsumerState<MiniWorkoutPage> {
  int? minutes;
  String split = 'ABC', goal = 'hipertrofia', experience = 'iniciante';
  final equipment = <String>{'Barra', 'Haltere', 'Cabo', 'Máquina'};
  final preferences = TextEditingController();
  bool busy = false;
  void change(VoidCallback update) => setState(() {
        update();
        workout = null;
        error = null;
      });
  @override
  void dispose() {
    preferences.dispose();
    super.dispose();
  }

  String? error;
  Map<String, dynamic>? workout;
  Future<void> generate() async {
    setState(() {
      busy = true;
      error = null;
      workout = null;
    });
    try {
      final focus = widget.focus ??
          ref.read(trainingFocusProvider).valueOrNull ??
          'musculacao';
      final gym = focus == 'musculacao';
      final result = await (widget.api ?? SquadService())
          .request('POST', '/v1/ai/workouts', {
        'mode': 'generate',
        'focus': focus,
        'minutes': minutes ?? (gym ? 60 : 15),
        'split': gym ? split : 'FULL_BODY',
        'goal': gym ? goal : 'condicionamento',
        'experience': gym ? experience : 'iniciante',
        'text': preferences.text.trim(),
        'equipment': ['Peso Corporal', if (gym) ...equipment]
      });
      final draft = Map<String, dynamic>.from(result['workout']);
      draft['focus'] = focus;
      if (focus == 'calistenia') {
        for (final day in draft['days']) {
          for (final exercise in day['exercises']) {
            exercise['trainingMode'] = 'calistenia';
            exercise['measurementType'] = 'reps';
          }
        }
      }
      if (mounted) setState(() => workout = draft);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      final id = await ref
          .read(workoutDaoProvider)
          .importWorkoutSplit(workout!, preservePrescription: true);
      await ref.read(workoutDaoProvider).setActiveSplit(id);
      if (!mounted) return;
      if (widget.onboarding) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomePage()), (_) => false);
      } else {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted)
        setState(() {
          busy = false;
          error = 'Não foi possível salvar. Tente novamente.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focus ??
        ref.watch(trainingFocusProvider).valueOrNull ??
        'musculacao';
    final gym = focus == 'musculacao';
    return PopScope(
        canPop: !busy,
        child: Scaffold(
            appBar: AppBar(
                title: Text(gym
                    ? 'Treino de musculação com IA'
                    : 'Mini treino com IA')),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              Text(
                  gym
                      ? 'Um treino para sua rotina.'
                      : 'Comece com o que você tem.',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(gym
                  ? 'Escolha a divisão e o tempo por sessão. A IA prepara os dias para você revisar antes de salvar.'
                  : 'Uma sessão inicial simples de calistenia, com peso corporal. Revise os exercícios antes de salvar.'),
              const SizedBox(height: 24),
              const Text('Tempo por sessão (aproximado)'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final value in gym ? [30, 45, 60, 75, 90] : [10, 15, 20])
                  ChoiceChip(
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .2),
                      label: Text('$value min'),
                      selected: (minutes ?? (gym ? 60 : 15)) == value,
                      onSelected:
                          busy ? null : (_) => change(() => minutes = value)),
              ]),
              if (gym) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                    value: split,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Divisão de treino'),
                    items: const [
                      DropdownMenuItem(
                          value: 'FULL_BODY',
                          child: Text('Corpo inteiro · um dia')),
                      DropdownMenuItem(
                          value: 'AB',
                          child: Text('AB · superiores / inferiores')),
                      DropdownMenuItem(
                          value: 'ABC',
                          child: Text('ABC · empurrar / puxar / pernas')),
                      DropdownMenuItem(
                          value: 'ABCD', child: Text('ABCD · quatro dias')),
                      DropdownMenuItem(
                          value: 'ABCDE', child: Text('ABCDE · cinco dias')),
                    ],
                    onChanged:
                        busy ? null : (value) => change(() => split = value!)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: goal,
                    decoration: const InputDecoration(labelText: 'Objetivo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'hipertrofia', child: Text('Hipertrofia')),
                      DropdownMenuItem(value: 'forca', child: Text('Força')),
                      DropdownMenuItem(
                          value: 'condicionamento',
                          child: Text('Condicionamento')),
                    ],
                    onChanged:
                        busy ? null : (value) => change(() => goal = value!)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: experience,
                    decoration: const InputDecoration(labelText: 'Experiência'),
                    items: const [
                      DropdownMenuItem(
                          value: 'iniciante', child: Text('Iniciante')),
                      DropdownMenuItem(
                          value: 'intermediario', child: Text('Intermediário')),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => change(() => experience = value!)),
                const SizedBox(height: 20),
                const Text('Equipamentos disponíveis'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final value in ['Barra', 'Haltere', 'Cabo', 'Máquina'])
                    FilterChip(
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .2),
                        label: Text(value),
                        selected: equipment.contains(value),
                        onSelected: busy
                            ? null
                            : (selected) => change(() {
                                  if (selected) {
                                    equipment.add(value);
                                  } else {
                                    equipment.remove(value);
                                  }
                                })),
                ]),
                const SizedBox(height: 8),
                const Text(
                    'Peso corporal também pode ser incluído. O tempo considera pausas e troca de aparelhos; a espera na academia varia.'),
              ] else ...[
                const SizedBox(height: 20),
                const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.accessibility_new),
                    title: Text('Peso corporal'),
                    subtitle:
                        Text('Chão e parede, sem inventar cargas em quilos.')),
              ],
              const SizedBox(height: 20),
              TextField(
                  controller: preferences,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: InputDecoration(
                      labelText: 'Preferências e contexto',
                      hintText: gym
                          ? 'Ex.: academia cheia, prefiro halteres, quero priorizar costas e tenho 60 minutos por sessão.'
                          : 'Ex.: estou começando e prefiro exercícios em pé.'),
                  onChanged: (_) {
                    if (workout != null) change(() {});
                  }),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: busy ? null : generate,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(busy
                      ? 'Preparando…'
                      : workout == null
                          ? 'Gerar sugestão'
                          : 'Gerar outra sugestão')),
              if (busy)
                const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator()),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              if (workout != null) ...[
                const SizedBox(height: 28),
                Text(workout!['nome'],
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Rascunho · ainda não salvo'),
                for (final day in workout!['days']) ...[
                  const SizedBox(height: 16),
                  Text('${day['letra']} · ${day['nome']}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final ex in day['exercises'])
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(ex['nome'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 8),
                                      Text(
                                          '${ex['volume']} · descanso ${ex['tempoDescansoSegundos']} s'),
                                      Text(ex['equipamento']),
                                      if ((ex['link'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        TextButton.icon(
                                            onPressed: () => openReferenceVideo(
                                                context, ex['link'],
                                                title: ex['nome']),
                                            icon: const Icon(
                                                Icons.play_circle_outline),
                                            label: const Text('Ver execução')),
                                      if ((ex['observacoes'] ?? '').isNotEmpty)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(ex['observacoes']))
                                    ])))),
                ],
                const Text(
                    'Interrompa se houver dor ou mal-estar. A sugestão não substitui uma avaliação individual.'),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: busy ? null : save,
                    child: const Text('Salvar rotina')),
              ],
            ])));
  }
}
