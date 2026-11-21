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

Future<XFile> reportCover(Map<String, dynamic> report) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 720, 720),
      Paint()..color = const Color(0xff111827));
  void text(String value, double y, double size, Color color) {
    final p = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                color: color, fontSize: size, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '…')
      ..layout(maxWidth: 600);
    p.paint(canvas, Offset(60, y));
  }

  final sets = report['sets'] as List;
  final completed = sets.where((s) => s['completed'] == true).toList();
  text('METE MARCHA · TREINO CONCLUÍDO', 60, 22, const Color(0xffa99eff));
  text(report['title'], 135, 42, Colors.white);
  text('${completed.map((s) => s['exercise']).toSet().length} exercícios', 340,
      38, Colors.white);
  text(
      '${completed.length} execuções · ${(report['duration_seconds'] as int) ~/ 60} min',
      405,
      30,
      Colors.white70);
  text('Toque para ver o treino completo', 590, 24, const Color(0xffa99eff));
  final image = await recorder.endRecording().toImage(720, 720);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return XFile.fromData(bytes!.buffer.asUint8List(),
      name: 'treino.png', mimeType: 'image/png');
}

class WorkoutReportPage extends StatelessWidget {
  const WorkoutReportPage({super.key, required this.report});
  final Map<String, dynamic> report;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Relatório do treino')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(report['title'],
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
            '${report['date']} · ${(report['duration_seconds'] as num) ~/ 60} minutos'),
        const SizedBox(height: 24),
        const Text('Execuções na ordem registrada'),
        const SizedBox(height: 12),
        for (final s in report['sets'])
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s['exercise']} · série ${s['number']}',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(s['completed'] == true
                        ? '${s['weight_kg']} kg × ${s['reps']} repetições · ${s['side']}'
                        : 'Não realizada'),
                    if ((s['equipment'] ?? '').isNotEmpty) Text(s['equipment']),
                    if (s['rpe'] != null || s['rir'] != null)
                      Text('RPE: ${s['rpe'] ?? '—'} · RIR: ${s['rir'] ?? '—'}'),
                    if ((s['notes'] ?? '').isNotEmpty) Text(s['notes']),
                    const Divider(),
                  ])),
      ]));
}
