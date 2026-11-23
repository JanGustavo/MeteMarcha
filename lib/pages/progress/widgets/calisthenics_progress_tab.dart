import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calisthenics/calisthenics_metrics.dart';
import '../../../core/providers/progress_extended_provider.dart';

class CalisthenicsProgressTab extends ConsumerWidget {
  const CalisthenicsProgressTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(allCompletedLogsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
              child: Text('Não foi possível carregar as execuções.')),
          data: (logs) {
            final groups = <String, List<CalisthenicsMetrics>>{};
            final ordered = [...logs]..sort((a, b) => a.data.compareTo(b.data));
            for (final log in ordered) {
              final m = CalisthenicsMetrics.decode(log.trainingMetrics);
              if (m != null)
                groups.putIfAbsent(m.comparisonKey, () => []).add(m);
            }
            return ListView(padding: const EdgeInsets.all(24), children: [
              Text('Sua evolução na calistenia',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text(
                  'Repetições, tempo e distância têm suas próprias unidades. Comparamos somente a mesma variação, carga e assistência; mudanças de dificuldade não são convertidas em quilos.'),
              const SizedBox(height: 20),
              if (groups.isEmpty)
                const Text(
                    'Registre uma execução no modo calistenia e conclua o treino para começar.'),
              for (final group in groups.values)
                Builder(builder: (context) {
                  final first = group.first, last = group.last;
                  final best =
                      group.reduce((a, b) => a.value > b.value ? a : b);
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(last.variation,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Text(last.loadLabel),
                                if (last.apparatus.isNotEmpty)
                                  Text(last.apparatus),
                                if (last.assistance.isNotEmpty)
                                  Text('Assistência: ${last.assistance}'),
                                const SizedBox(height: 12),
                                Text(
                                    'Primeira: ${first.amount} · Última: ${last.amount}'),
                                Text(
                                    'Melhor: ${best.amount} · ${group.length} execuções'),
                                if (group.length > 1)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Semantics(
                                          label:
                                              'Histórico de ${first.amount} até ${last.amount}',
                                          child: SizedBox(
                                              height: 90,
                                              width: double.infinity,
                                              child: CustomPaint(
                                                  painter: _MetricLine(
                                                      [
                                                    for (final m in group)
                                                      m.value
                                                  ],
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary))))),
                              ])));
                }),
            ]);
          });
}

class _MetricLine extends CustomPainter {
  _MetricLine(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final low = values.reduce(math.min), high = values.reduce(math.max);
    final span = high - low;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
          4 + (size.width - 8) * i / (values.length - 1),
          span == 0
              ? size.height / 2
              : 4 + (size.height - 8) * (1 - (values[i] - low) / span));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_MetricLine old) =>
      old.values != values || old.color != color;
}
