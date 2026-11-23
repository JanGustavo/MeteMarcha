import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/media/exercise_catalog.dart';
import '../../core/providers/providers.dart';
import '../home/home_page.dart';
import 'setup_page.dart';

class RoutineBuilderPage extends ConsumerStatefulWidget {
  const RoutineBuilderPage(
      {super.key,
      this.focus = 'musculacao',
      this.onboarding = false,
      this.onCreated});
  final String focus;
  final bool onboarding;
  final ValueChanged<int>? onCreated;
  @override
  ConsumerState<RoutineBuilderPage> createState() => _RoutineBuilderPageState();
}

class _RoutineBuilderPageState extends ConsumerState<RoutineBuilderPage> {
  final name = TextEditingController();
  final names = List.generate(5, (_) => TextEditingController());
  final days = List.generate(5, (_) => <Map<String, dynamic>>[]);
  int count = 3;
  bool busy = false;
  String? error;
  late String mode = widget.focus;
  @override
  void dispose() {
    name.dispose();
    for (final c in names) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> add(int day) async {
    final catalog = await ExerciseCatalog.load();
    if (!mounted) return;
    final entry = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _CatalogPicker(entries: catalog.entries));
    if (entry == null || !mounted) return;
    if (days[day].any((e) => e['catalogId'] == entry['id'])) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse exercício já está neste dia.')));
      return;
    }
    setState(() => days[day].add({
          'catalogId': entry['id'],
          'nome': entry['name'],
          'grupoMuscular': entry['muscle'],
          'equipamento': entry['equipment'],
          'trainingMode': mode,
          'measurementType': {'plank', 'side-plank'}.contains(entry['id'])
              ? 'seconds'
              : 'reps',
          'link': entry['video']?['url']
        }));
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || name.text.trim().length > 100) {
      setState(() => error = 'Dê um nome à rotina com até 100 caracteres.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = await ref.read(workoutDaoProvider).importWorkoutSplit({
        'nome': name.text.trim(),
        'tipo': 'CUSTOM',
        'days': [
          for (var i = 0; i < count; i++)
            {
              'letra': String.fromCharCode(65 + i),
              'nome': names[i].text.trim().isEmpty
                  ? 'Dia ${String.fromCharCode(65 + i)}'
                  : names[i].text.trim(),
              'exercises': days[i]
            }
        ]
      }, preservePrescription: true);
      await ref.read(workoutDaoProvider).setActiveSplit(id);
      ref.invalidate(splitsProvider);
      ref.invalidate(activeSplitProvider);
      ref.invalidate(activeSplitDaysProvider);
      if (!mounted) return;
      if (widget.onCreated != null) {
        widget.onCreated!(id);
        return;
      }
      if (widget.onboarding) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomePage()), (_) => false);
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SetupPage(initialTab: 2)));
      }
    } catch (_) {
      if (mounted)
        setState(
            () => error = 'Não foi possível criar a rotina. Tente novamente.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Montar minha rotina')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text(
            'Escolha os dias e adicione exercícios agora ou depois. A ordem aqui será a ordem de execução. Descanso e medições podem ser ajustados na configuração.'),
        const SizedBox(height: 16),
        TextField(
            controller: name,
            enabled: !busy,
            maxLength: 100,
            decoration: const InputDecoration(
                labelText: 'Nome da rotina',
                hintText: 'Ex.: Meu treino em casa')),
        SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'musculacao', label: Text('Musculação')),
              ButtonSegment(value: 'calistenia', label: Text('Calistenia'))
            ],
            selected: {
              mode
            },
            onSelectionChanged:
                busy ? null : (v) => setState(() => mode = v.first)),
        const SizedBox(height: 8),
        const Text(
            'Essa escolha é o padrão para os próximos exercícios adicionados. Cada exercício pode ter sua modalidade.'),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
            initialValue: count,
            decoration:
                const InputDecoration(labelText: 'Dias diferentes na divisão'),
            items: [
              for (var i = 1; i <= 5; i++)
                DropdownMenuItem(
                    value: i, child: Text('$i ${i == 1 ? 'dia' : 'dias'}'))
            ],
            onChanged: busy ? null : (v) => setState(() => count = v!)),
        for (var d = 0; d < count; d++) ...[
          const SizedBox(height: 24),
          Text('Dia ${String.fromCharCode(65 + d)}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
              controller: names[d],
              enabled: !busy,
              maxLength: 100,
              decoration: const InputDecoration(
                  labelText: 'Nome do dia (opcional)',
                  hintText: 'Ex.: Empurrar e core')),
          for (var i = 0; i < days[d].length; i++)
            Card(
                key: ValueKey('$d:${days[d][i]['catalogId']}'),
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${days[d][i]['nome']}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              '${days[d][i]['equipamento']} · ${days[d][i]['trainingMode']}'),
                          TextFormField(
                              initialValue: days[d][i]['volume'],
                              enabled: !busy,
                              decoration: const InputDecoration(
                                  labelText:
                                      'Meta de séries e execução (opcional)',
                                  hintText: 'Ex.: 3x8 ou 3x30s'),
                              onChanged: (v) => days[d][i]['volume'] =
                                  v.trim().isEmpty ? null : v.trim()),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    tooltip: 'Mover para cima',
                                    onPressed: busy || i == 0
                                        ? null
                                        : () => setState(() {
                                              final e = days[d].removeAt(i);
                                              days[d].insert(i - 1, e);
                                            }),
                                    icon: const Icon(Icons.arrow_upward)),
                                IconButton(
                                    tooltip: 'Remover da rotina',
                                    onPressed: busy
                                        ? null
                                        : () =>
                                            setState(() => days[d].removeAt(i)),
                                    icon: const Icon(Icons.delete_outline))
                              ]),
                        ]))),
          OutlinedButton.icon(
              onPressed: busy ? null : () => add(d),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar exercício do catálogo')),
        ],
        if (error != null)
          Text(error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Criando…' : 'Criar rotina')),
        if (busy) const LinearProgressIndicator(),
      ]));
}

class _CatalogPicker extends StatefulWidget {
  const _CatalogPicker({required this.entries});
  final List<Map<String, dynamic>> entries;
  @override
  State<_CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<_CatalogPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final entries = widget.entries
        .where((e) => ExerciseCatalog.normalize(
                '${e['name']} ${e['muscle']} ${e['aliases']}')
            .contains(ExerciseCatalog.normalize(query)))
        .toList();
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Buscar exercício ou grupo muscular',
                      prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => query = v)),
              const SizedBox(height: 12),
              Expanded(
                  child: ListView(children: [
                for (final e in entries)
                  ListTile(
                      title: Text(e['name']),
                      subtitle: Text('${e['muscle']} · ${e['equipment']}'),
                      trailing: Icon(e['video'] == null
                          ? Icons.add
                          : Icons.play_circle_outline),
                      onTap: () => Navigator.pop(context, e)),
                if (entries.isEmpty)
                  const ListTile(
                      title: Text(
                          'Nenhum exercício encontrado. Você pode criar exercícios pela configuração.'))
              ]))
            ])));
  }
}
