import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gym_tracker/core/database/app_database.dart'
    hide isNull, isNotNull;
import 'package:gym_tracker/core/calisthenics/calisthenics_metrics.dart';
import 'package:gym_tracker/pages/workout/widgets/calisthenics_panel.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

void main() {
  testWidgets('sustentação é registrada em segundos sem peso inventado',
      (tester) async {
    open.overrideFor(OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.exerciseDao.insertExercise(ExercisesCompanion.insert(
        nome: 'Prancha teste',
        grupoMuscular: 'Core',
        trainingMode: const Value('calistenia'),
        measurementType: const Value('seconds')));
    final exercise = (await db.exerciseDao.getById(id))!;
    final session = await db
        .into(db.workoutSessions)
        .insert(WorkoutSessionsCompanion.insert(data: '2026-11-22'));
    var saved = 0;
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: CalisthenicsPanel(
                        db: db,
                        exercise: exercise,
                        sessionId: session,
                        onSaved: () async {
                          saved++;
                        }))))));
    await tester.pumpAndSettle();
    final quantity = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.labelText == 'Tempo em segundos');
    await tester.enterText(quantity, '45');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final button = find.text('Registrar execução');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final logs = await db.logDao.getLogsForSession(session);
    expect(logs.length, 1);
    await tester.pumpAndSettle();
    expect(saved, 1);
    expect(logs.single.peso, 0);
    expect(logs.single.repeticoes, 0);
    final metrics = CalisthenicsMetrics.decode(logs.single.trainingMetrics)!;
    expect(metrics.value, 45);
    expect(metrics.measure, 'seconds');
    expect(metrics.externalKg, isNull);
  });
}
