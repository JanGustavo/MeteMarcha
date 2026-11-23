import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/calisthenics/calisthenics_metrics.dart';
import '../../../core/consistency/weekly_consistency.dart';
import '../../../core/consistency/consistency_provider.dart';
import '../../consistency/reward_celebration.dart';

class CalisthenicsPanel extends ConsumerStatefulWidget {
  const CalisthenicsPanel(
      {super.key,
      required this.db,
      required this.exercise,
      required this.sessionId,
      required this.onSaved});
  final AppDatabase db;
  final Exercise exercise;
  final int sessionId;
  final Future<void> Function() onSaved;
  @override
  ConsumerState<CalisthenicsPanel> createState() => _CalisthenicsPanelState();
}

class _CalisthenicsPanelState extends ConsumerState<CalisthenicsPanel> {
  final quantity = TextEditingController(),
      kg = TextEditingController(),
      object = TextEditingController(),
      assistance = TextEditingController();
  late final variation = TextEditingController(text: widget.exercise.nome);
  late String measure = widget.exercise.measurementType;
  String source = 'none';
  bool busy = false;
  String? error;
  late Future<List<ExerciseLog>> logs = load();
  Future<List<ExerciseLog>> load() async {
    final query = widget.db.select(widget.db.exerciseLogs).join([
      innerJoin(
          widget.db.workoutSessions,
          widget.db.workoutSessions.id
              .equalsExp(widget.db.exerciseLogs.sessionId))
    ])
      ..where(widget.db.exerciseLogs.exerciseId.equals(widget.exercise.id) &
          widget.db.exerciseLogs.concluido.equals(true) &
          (widget.db.workoutSessions.status.equals('concluido') |
              widget.db.workoutSessions.id.equals(widget.sessionId)))
      ..orderBy([OrderingTerm.desc(widget.db.exerciseLogs.data)]);
    return (await query.get())
        .map((r) => r.readTable(widget.db.exerciseLogs))
        .toList();
  }

  @override
  void dispose() {
    for (final c in [quantity, kg, object, assistance, variation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(quantity.text.replaceAll(',', '.'));
    final external = {'none', 'unknown'}.contains(source)
        ? null
        : double.tryParse(kg.text.replaceAll(',', '.'));
    final metrics = CalisthenicsMetrics(
        measure: measure,
        value: value ?? 0,
        variation: variation.text.trim(),
        loadSource: source,
        externalKg: external,
        apparatus: object.text.trim(),
        assistance: assistance.text.trim());
    if (!metrics.valid) {
      setState(() => error =
          'Confira a quantidade, a variação e a carga. Para carga estimada ou desconhecida, identifique o objeto.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final previous = await logs;
      var best = 0.0;
      for (final log in previous) {
        final old = CalisthenicsMetrics.decode(log.trainingMetrics);
        if (old != null &&
            old.comparisonKey == metrics.comparisonKey &&
            old.value > best) best = old.value;
      }
      final current =
          await widget.db.logDao.getLogsForSession(widget.sessionId);
      final series = current
              .where((l) => l.exerciseId == widget.exercise.id)
              .fold<int>(0, (n, l) => l.serie > n ? l.serie : n) +
          1;
      final id = await widget.db.transaction(() async {
        final inserted = await widget.db.logDao.insertLog(
            ExerciseLogsCompanion.insert(
                exerciseId: widget.exercise.id,
                sessionId: widget.sessionId,
                data: DateTime.now().toIso8601String(),
                peso: 0,
                repeticoes: measure == 'reps' ? value!.toInt() : 0,
                serie: Value(series),
                trainingMetrics: Value(metrics.encode()),
                observacoes: Value(metrics.summary),
                equipamento: Value(object.text.trim().isEmpty
                    ? 'Peso Corporal'
                    : object.text.trim())));
        await (widget.db.update(widget.db.exercises)
              ..where((e) => e.id.equals(widget.exercise.id)))
            .write(ExercisesCompanion(measurementType: Value(measure)));
        return inserted;
      });
      if (mounted) {
        setState(() {
          logs = load();
        });
        quantity.clear();
      }
      await widget.onSaved();
      if (best > 0 && metrics.value > best && mounted) {
        final reward = EarnedReward(
            id: 'calis:$id:${DateTime.now().microsecondsSinceEpoch}',
            title: 'Recorde pessoal · ${metrics.variation}',
            detail:
                '${metrics.amount}. Comparação na mesma variação, carga e assistência. ${metrics.loadLabel}.',
            kind: 'pr',
            value: metrics.amount,
            earnedAt: DateTime.now(),
            seen: true);
        await ref.read(rewardProvider.notifier).add(reward);
        if (mounted) await showRewardCelebration(context, reward);
      }
    } catch (_) {
      if (mounted)
        setState(() => error =
            'Não foi possível salvar. Confira o registro antes de tentar novamente.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Execução de calistenia',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            initialValue: measure,
            decoration: const InputDecoration(labelText: 'O que registrar'),
            items: const [
              DropdownMenuItem(value: 'reps', child: Text('Repetições')),
              DropdownMenuItem(
                  value: 'seconds',
                  child: Text('Tempo de sustentação · segundos')),
              DropdownMenuItem(
                  value: 'meters', child: Text('Distância · metros'))
            ],
            onChanged: busy ? null : (v) => setState(() => measure = v!)),
        const SizedBox(height: 12),
        TextField(
            controller: quantity,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: measure == 'reps'
                    ? 'Repetições'
                    : measure == 'seconds'
                        ? 'Tempo em segundos'
                        : 'Distância em metros')),
        const SizedBox(height: 12),
        TextField(
            controller: variation,
            enabled: !busy,
            maxLength: 200,
            decoration:
                const InputDecoration(labelText: 'Variação do exercício')),
        DropdownButtonFormField<String>(
            initialValue: source,
            decoration: const InputDecoration(labelText: 'Carga externa'),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Sem carga extra')),
              DropdownMenuItem(
                  value: 'measured', child: Text('Pesada em balança')),
              DropdownMenuItem(
                  value: 'reported', child: Text('Informada no equipamento')),
              DropdownMenuItem(value: 'estimated', child: Text('Estimada')),
              DropdownMenuItem(
                  value: 'unknown', child: Text('Peso desconhecido'))
            ],
            onChanged: busy ? null : (v) => setState(() => source = v!)),
        if (!{'none', 'unknown'}.contains(source)) ...[
          const SizedBox(height: 12),
          TextField(
              controller: kg,
              enabled: !busy,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Carga externa em kg')),
        ],
        if (source != 'none') ...[
          const SizedBox(height: 12),
          TextField(
              controller: object,
              enabled: !busy,
              maxLength: 200,
              decoration: const InputDecoration(
                  labelText: 'Objeto ou equipamento',
                  hintText: 'Ex.: mochila azul, peso artesanal A')),
        ],
        const SizedBox(height: 12),
        TextField(
            controller: assistance,
            enabled: !busy,
            maxLength: 200,
            decoration: const InputDecoration(
                labelText: 'Assistência (opcional)',
                hintText: 'Ex.: elástico verde, apoio dos joelhos')),
        const Text(
            'Seu peso corporal não é somado à carga externa. As comparações usam a mesma variação, carga e assistência.'),
        if (error != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: busy ? null : save,
            icon: const Icon(Icons.add),
            label: const Text('Registrar execução')),
        FutureBuilder<List<ExerciseLog>>(
            future: logs,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return TextButton(
                    onPressed: () => setState(() {
                          logs = load();
                        }),
                    child: const Text('Tentar carregar execuções novamente'));
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final data = snapshot.data!
                  .where((l) => l.trainingMetrics != null)
                  .toList();
              if (data.isEmpty)
                return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                        'Registre a primeira execução para começar seu histórico nesta métrica.'));
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('Execuções registradas',
                        style: Theme.of(context).textTheme.titleMedium),
                    for (final log in data.take(15))
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              CalisthenicsMetrics.decode(log.trainingMetrics)
                                      ?.summary ??
                                  'Métrica indisponível'),
                          subtitle: Text(
                              '${log.data.substring(0, 10)} · ${CalisthenicsMetrics.decode(log.trainingMetrics)?.variation ?? ''}'),
                          trailing: log.sessionId == widget.sessionId
                              ? IconButton(
                                  tooltip: 'Excluir execução',
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          await widget.db.logDao
                                              .deleteLog(log.id);
                                          if (mounted)
                                            setState(() {
                                              logs = load();
                                            });
                                          await widget.onSaved();
                                        },
                                  icon: const Icon(Icons.delete_outline))
                              : null),
                  ]);
            }),
      ]);
}
