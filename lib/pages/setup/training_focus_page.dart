import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/training_focus_provider.dart';
import 'mini_workout_page.dart';

class TrainingFocusPage extends ConsumerStatefulWidget {
  const TrainingFocusPage({super.key, this.editing = false});
  final bool editing;
  @override
  ConsumerState<TrainingFocusPage> createState() => _TrainingFocusPageState();
}

class _TrainingFocusPageState extends ConsumerState<TrainingFocusPage> {
  bool saving = false;
  String? selected;
  int step = 0;
  @override
  void initState() {
    super.initState();
    selected = ref.read(trainingFocusProvider).valueOrNull;
  }

  Future<void> choose(String focus, {bool ai = false}) async {
    final navigator = Navigator.of(context);
    setState(() => saving = true);
    try {
      await ref.read(trainingFocusProvider.notifier).select(focus);
      if (ai && navigator.mounted) {
        navigator.push(MaterialPageRoute(
            builder: (_) => MiniWorkoutPage(onboarding: true, focus: focus)));
      }
      if (!mounted) return;
      if (widget.editing) {
        Navigator.pop(context);
      } else {
        setState(() => saving = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar:
          widget.editing ? AppBar(title: const Text('Foco do treino')) : null,
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 24),
        if (!widget.editing) ...[
          Text('VAMOS COMEÇAR · ${step + 1} DE 2',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: (step + 1) / 2),
          const SizedBox(height: 28)
        ],
        if (step == 0) ...[
          Text('Qual é o seu foco?',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          const Text(
              'Escolha por onde quer começar. Você pode combinar musculação e calistenia na mesma conta e mudar o foco depois.'),
          const SizedBox(height: 24),
          for (final entry in {
            'musculacao': [
              'Musculação',
              'Máquinas, halteres e barras.',
              'Força com equipamentos'
            ],
            'calistenia': [
              'Calistenia',
              'Peso corporal e recursos simples.',
              'Movimento em qualquer lugar'
            ]
          }.entries)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: selected == entry.key
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: saving
                            ? null
                            : () => setState(() => selected = entry.key),
                        child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(entry.value[0],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge)),
                                    Icon(selected == entry.key
                                        ? Icons.check_circle
                                        : Icons.circle_outlined)
                                  ]),
                                  const SizedBox(height: 12),
                                  Text(entry.value[1]),
                                  const SizedBox(height: 6),
                                  Text(entry.value[2],
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall)
                                ]))))),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: selected == null || saving
                  ? null
                  : () => widget.editing
                      ? choose(selected!)
                      : setState(() => step = 1),
              child: Text(widget.editing ? 'Salvar foco' : 'Continuar')),
        ] else ...[
          Text('Seu primeiro treino.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          const Text(
              'Comece simples. Depois de treinar, acompanhe a evolução e compartilhe os momentos com seu squad.'),
          const SizedBox(height: 28),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fitness_center_outlined),
              title: const Text('Um passo de cada vez'),
              subtitle:
                  const Text('Escolha os exercícios e registre cada série.')),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Seu progresso, visível'),
              subtitle:
                  const Text('Consulte seu histórico e veja o que mudou.')),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Treine em companhia'),
              subtitle: const Text('Convide pessoas e compartilhe no squad.')),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: saving ? null : () => choose(selected!, ai: true),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Montar meu primeiro treino com IA')),
          OutlinedButton(
              onPressed: saving ? null : () => choose(selected!),
              child: const Text('Prefiro escolher ou importar um treino')),
          TextButton(
              onPressed: saving ? null : () => setState(() => step = 0),
              child: const Text('Voltar ao foco')),
        ],
        if (saving) const LinearProgressIndicator(),
      ])));
}
