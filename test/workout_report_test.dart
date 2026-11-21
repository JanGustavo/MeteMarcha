import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/pages/squads/workout_report.dart';

void main() {
  final report = <String, dynamic>{
    'title': 'Treino A',
    'date': '2026-11-20',
    'duration_seconds': 3600,
    'sets': [
      for (var i = 1; i <= 60; i++)
        {
          'exercise': 'Exercício $i',
          'number': i,
          'weight_kg': 20,
          'reps': 10,
          'side': 'ambos',
          'completed': true,
          'equipment': 'barra',
          'notes': 'Execução $i'
        }
    ]
  };
  testWidgets('relatório permite alcançar a última execução', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: WorkoutReportPage(report: report)));
    expect(find.text('Exercício 1 · série 1'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Exercício 60 · série 60'),
        find.byType(Scrollable), const Offset(0, -500));
    expect(find.text('Exercício 60 · série 60'), findsOneWidget);
  });
  testWidgets('capa do relatório é uma imagem PNG quadrada', (tester) async {
    await tester.runAsync(() async {
      final file = await reportCover(report);
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 720);
      expect(frame.image.height, 720);
      frame.image.dispose();
      codec.dispose();
    });
  });
}
