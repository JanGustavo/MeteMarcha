import '../../core/calisthenics/calisthenics_metrics.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'dart:ui' show FontFeature;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/database/app_database.dart';

Future<Map<String, dynamic>> snapshotWorkout(
    AppDatabase db, WorkoutSession session) async {
  final logs = await (db.select(db.exerciseLogs)
        ..where((l) => l.sessionId.equals(session.id)))
      .get();
  logs.sort((a, b) {
    final c = a.data.compareTo(b.data);
    return c == 0 ? a.id.compareTo(b.id) : c;
  });
  final exercises = {
    for (final e in await db.select(db.exercises).get()) e.id: e.nome
  };
  final day = session.dayId == null
      ? null
      : await (db.select(db.workoutDays)
            ..where((d) => d.id.equals(session.dayId!)))
          .getSingleOrNull();
  return {
    'version': 1,
    'title':
        day == null ? 'Treino concluído' : 'Treino ${day.letra} · ${day.nome}',
    'date': session.data,
    'duration_seconds': session.duracaoSegundos ?? 0,
    'sets': [
      for (final l in logs)
        {
          'exercise': exercises[l.exerciseId] ?? 'Exercício',
          'number': l.serie,
          'weight_kg': l.peso,
          if (l.trainingMetrics != null)
            'calisthenics':
                CalisthenicsMetrics.decode(l.trainingMetrics)?.toJson(),
          'reps': l.repeticoes,
          'side': l.lado,
          'completed': l.concluido,
          'equipment': l.equipamento ?? '',
          'notes': l.observacoes ?? '',
          'rpe': l.rpe,
          'rir': l.rir,
          'at': l.data
        }
    ]
  };
}

String reportNumber(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1).replaceAll('.', ',');
String reportDate(dynamic raw) {
  final date = DateTime.tryParse(raw?.toString() ?? '');
  return date == null
      ? 'Treino compartilhado'
      : DateFormat('dd/MM/yyyy · HH:mm').format(date.toLocal());
}

String reportDuration(num seconds) {
  final minutes = seconds ~/ 60;
  return minutes >= 60
      ? '${minutes ~/ 60}h ${minutes % 60}min'
      : '${minutes}min';
}

Future<XFile> reportCover(Map<String, dynamic> report) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const ink = Color(0xfff3f4f8),
      muted = Color(0xffa8afc0),
      accent = Color(0xffb8acf9);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 720, 720),
      Paint()..color = const Color(0xff101622));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 48, 64, 6), const Radius.circular(3)),
      Paint()..color = accent);
  void text(String value, double x, double y, double size, Color color,
      {double width = 624, int lines = 1}) {
    final painter = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                color: color,
                fontSize: size,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                height: 1.25)),
        textDirection: TextDirection.ltr,
        maxLines: lines,
        ellipsis: '…')
      ..layout(maxWidth: width);
    painter.paint(canvas, Offset(x, y));
  }

  final completed =
      (report['sets'] as List).where((s) => s['completed'] == true).toList();
  text('METE MARCHA', 48, 80, 20, accent);
  text('TREINO CONCLUÍDO', 48, 133, 16, muted);
  text(report['title'], 48, 173, 42, ink, lines: 3);
  text(reportDate(report['date']), 48, 350, 21, muted);
  canvas.drawLine(const Offset(48, 410), const Offset(672, 410),
      Paint()..color = const Color(0xff303746));
  final values = [
    completed.map((s) => s['exercise']).toSet().length.toString(),
    completed.length.toString(),
    reportDuration(report['duration_seconds'])
  ];
  final labels = ['exercícios', 'execuções', 'duração'];
  for (var i = 0; i < 3; i++) {
    text(values[i], 48 + i * 210, 442, 36, ink, width: 200);
    text(labels[i], 48 + i * 210, 493, 18, muted, width: 200);
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 587, 624, 76), const Radius.circular(16)),
      Paint()..color = const Color(0xff29263f));
  text('VER RELATÓRIO COMPLETO', 70, 612, 20, accent);
  final arrow = Paint()
    ..color = accent
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(620, 625), const Offset(646, 625), arrow);
  canvas.drawLine(const Offset(638, 617), const Offset(646, 625), arrow);
  canvas.drawLine(const Offset(638, 633), const Offset(646, 625), arrow);
  final picture = recorder.endRecording();
  final image = await picture.toImage(720, 720);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return XFile.fromData(bytes!.buffer.asUint8List(),
      name: 'workout-report.png',
      path: 'workout-report.png',
      mimeType: 'image/png');
}

class WorkoutReportPage extends StatelessWidget {
  const WorkoutReportPage({super.key, required this.report});
  final Map<String, dynamic> report;
  @override
  Widget build(BuildContext context) {
    final sets = List<Map<String, dynamic>>.from(
        (report['sets'] as List).map((s) => Map<String, dynamic>.from(s)));
    final completed = sets.where((s) => s['completed'] == true).toList();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final groups = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < sets.length; i++) {
      final row = {...sets[i], 'row_index': i};
      if (groups.isEmpty || groups.last.last['exercise'] != row['exercise'])
        groups.add([]);
      groups.last.add(row);
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Relatório do treino')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text('TREINO COMPARTILHADO',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colors.primary, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text(report['title'],
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(reportDate(report['date']),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 24),
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    _Metric(
                        value:
                            '${completed.map((s) => s['exercise']).toSet().length}',
                        label: 'Exercícios'),
                    _Metric(value: '${completed.length}', label: 'Execuções'),
                    _Metric(
                        value: reportDuration(report['duration_seconds']),
                        label: 'Duração'),
                  ])),
              const SizedBox(height: 28),
              Text('Do início ao fim', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Todas as séries, na ordem em que foram registradas.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 20),
              for (final group in groups)
                Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.first['exercise'],
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          const Row(children: [
                            Expanded(
                                child: Text('SÉRIE',
                                    style: TextStyle(
                                        fontSize: 11, letterSpacing: 1))),
                            Expanded(
                                child: Text('CARGA',
                                    style: TextStyle(
                                        fontSize: 11, letterSpacing: 1))),
                            Expanded(
                                child: Text('EXECUÇÃO',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 11, letterSpacing: 1)))
                          ]),
                          for (final row in group)
                            Padding(
                                key: ValueKey('report-set-${row['row_index']}'),
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Expanded(
                                            child: Text('${row['number']}',
                                                style: theme
                                                    .textTheme.titleMedium)),
                                        Expanded(
                                            child: Text(
                                                row['completed'] == true
                                                    ? (row['calisthenics'] !=
                                                            null
                                                        ? CalisthenicsMetrics.fromJson(Map<
                                                                        String,
                                                                        dynamic>.from(
                                                                    row[
                                                                        'calisthenics']))
                                                                ?.loadLabel ??
                                                            '—'
                                                        : '${reportNumber(row['weight_kg'])} kg')
                                                    : '—',
                                                style: const TextStyle(
                                                    fontFeatures: [
                                                      FontFeature
                                                          .tabularFigures()
                                                    ]))),
                                        Expanded(
                                            child: Text(
                                                row['completed'] == true
                                                    ? (row['calisthenics'] !=
                                                            null
                                                        ? CalisthenicsMetrics.fromJson(Map<
                                                                        String,
                                                                        dynamic>.from(
                                                                    row[
                                                                        'calisthenics']))
                                                                ?.amount ??
                                                            '—'
                                                        : '${row['reps']}')
                                                    : 'Pulada',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                    fontFeatures: [
                                                      FontFeature
                                                          .tabularFigures()
                                                    ])))
                                      ]),
                                      if (row['side'] != 'ambos')
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text('Lado ${row['side']}',
                                                style:
                                                    theme.textTheme.bodySmall)),
                                      if ((row['equipment'] ?? '').isNotEmpty)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(row['equipment'],
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: colors
                                                            .onSurfaceVariant))),
                                      if (row['rpe'] != null ||
                                          row['rir'] != null)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                                'Esforço (RPE): ${row['rpe'] ?? '—'} · Reserva (RIR): ${row['rir'] ?? '—'}',
                                                style:
                                                    theme.textTheme.bodySmall)),
                                      if ((row['notes'] ?? '').isNotEmpty)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(row['notes'],
                                                style: theme
                                                    .textTheme.bodyMedium)),
                                    ])),
                        ])),
            ]));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall)
      ]));
}
