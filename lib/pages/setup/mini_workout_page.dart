import '../../core/media/reference_video_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/training_focus_provider.dart';
import '../../core/services/squad_service.dart';
import '../home/home_page.dart';

class MiniWorkoutPage extends ConsumerStatefulWidget {
  const MiniWorkoutPage({super.key, this.onboarding = false, this.focus});
  final bool onboarding;
  final String? focus;
  @override
  ConsumerState<MiniWorkoutPage> createState() => _MiniWorkoutPageState();
}

class _MiniWorkoutPageState extends ConsumerState<MiniWorkoutPage> {
  int minutes = 15;
  bool dumbbells = false, busy = false;
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
      final result = await SquadService().request('POST', '/v1/ai/workouts', {
        'mode': 'generate',
        'focus': focus,
        'minutes': minutes,
        'equipment': [
          'Peso Corporal',
          if (dumbbells && focus == 'musculacao') 'Haltere'
        ]
      });
      if (mounted)
        setState(() => workout = Map<String, dynamic>.from(result['workout']));
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
    return PopScope(
        canPop: !busy,
        child: Scaffold(
            appBar: AppBar(title: const Text('Mini treino com IA')),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Comece com o que você tem.',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                  'Foco: ${focus == 'calistenia' ? 'calistenia' : 'musculação'}. A IA sugere um treino inicial simples. Revise os exercícios antes de salvar e adapte ao que consegue fazer confortavelmente.'),
              const SizedBox(height: 24),
              const Text('Tempo disponível (aproximado)'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 10, label: Text('10 min')),
                    ButtonSegment(value: 15, label: Text('15 min')),
                    ButtonSegment(value: 20, label: Text('20 min'))
                  ],
                  selected: {
                    minutes
                  },
                  onSelectionChanged:
                      busy ? null : (v) => setState(() => minutes = v.first)),
              const SizedBox(height: 20),
              const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.accessibility_new),
                  title: Text('Peso corporal'),
                  subtitle: Text(
                      'Usar o chão e uma parede, sem inventar carga em quilos.')),
              if (focus == 'musculacao')
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: dumbbells,
                    onChanged:
                        busy ? null : (v) => setState(() => dumbbells = v),
                    title: const Text('Tenho halteres'),
                    subtitle: const Text(
                        'Incluir somente se estiverem disponíveis.')),
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
                    child: const Text('Salvar este treino')),
              ],
            ])));
  }
}
