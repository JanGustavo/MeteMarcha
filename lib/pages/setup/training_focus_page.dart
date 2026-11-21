import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/training_focus_provider.dart';

class TrainingFocusPage extends ConsumerStatefulWidget {
  const TrainingFocusPage({super.key, this.editing = false});
  final bool editing;
  @override
  ConsumerState<TrainingFocusPage> createState() => _TrainingFocusPageState();
}

class _TrainingFocusPageState extends ConsumerState<TrainingFocusPage> {
  bool saving = false;
  Future<void> choose(String focus) async {
    setState(() => saving = true);
    try {
      await ref.read(trainingFocusProvider.notifier).select(focus);
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
        const SizedBox(height: 32),
        Text('Qual é o seu foco?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        const Text(
            'Vamos usar essa escolha para adaptar suas sugestões de treino. Você pode trocar depois no perfil.'),
        const SizedBox(height: 32),
        for (final entry in {
          'musculacao': [
            'Musculação',
            'Treinos com máquinas, halteres e barras.',
            Icons.fitness_center
          ],
          'calistenia': [
            'Calistenia',
            'Treinos com peso corporal e recursos simples.',
            Icons.accessibility_new
          ]
        }.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                      contentPadding: const EdgeInsets.all(24),
                      leading: Icon(entry.value[2] as IconData),
                      title: Text(entry.value[0] as String),
                      subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(entry.value[1] as String)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: saving ? null : () => choose(entry.key)))),
        if (saving) const LinearProgressIndicator(),
      ])));
}
