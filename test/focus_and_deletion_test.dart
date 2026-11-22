import 'dart:ffi';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/core/database/app_database.dart'
    hide isNull, isNotNull;
import 'package:gym_tracker/core/providers/training_focus_provider.dart';
import 'package:gym_tracker/pages/setup/training_focus_page.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('foco é oferecido e a escolha fica salva', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TrainingFocusPage())));
    await tester.pumpAndSettle();
    expect(find.text('Qual é o seu foco?'), findsOneWidget);
    expect(find.text('Musculação'), findsOneWidget);
    await tester.tap(find.text('Calistenia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.text('Prefiro escolher ou importar um treino'));
    await tester.tap(find.text('Prefiro escolher ou importar um treino'));
    await tester.pumpAndSettle();
    expect(
        (await SharedPreferences.getInstance()).getString('mm.training.focus'),
        'calistenia');
  });
  test('foco persiste ao reabrir o controller', () async {
    final first = TrainingFocusController();
    await first.load();
    expect(first.state.valueOrNull, isNull);
    await first.select('calistenia');
    first.dispose();
    final next = TrainingFocusController();
    await next.load();
    expect(next.state.valueOrNull, 'calistenia');
    next.dispose();
  });
  test('excluir sessão remove apenas suas séries', () async {
    open.overrideFor(OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final exercise = await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
            nome: 'Teste exclusão', grupoMuscular: 'Peito'));
    final a = await db.into(db.workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
            data: '2026-11-21', status: const Value('concluido')));
    final b = await db.into(db.workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
            data: '2026-11-22', status: const Value('concluido')));
    for (final id in [a, b]) {
      await db.into(db.exerciseLogs).insert(ExerciseLogsCompanion.insert(
          exerciseId: exercise,
          sessionId: id,
          data: '2026-11-21',
          peso: 10,
          repeticoes: 8));
    }
    await db.workoutDao.deleteSession(a);
    expect((await db.select(db.workoutSessions).get()).map((s) => s.id), [b]);
    expect(
        (await db.select(db.exerciseLogs).get()).map((s) => s.sessionId), [b]);
  });
  test(
      'importação da IA preserva as séries sugeridas sem alterar exercício anterior',
      () async {
    open.overrideFor(OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.exercises).insert(ExercisesCompanion.insert(
        nome: 'Flexão na parede',
        grupoMuscular: 'Peito',
        volume: const Value('4x12')));
    await db.workoutDao.importWorkoutSplit({
      'nome': 'Mini',
      'tipo': 'CUSTOM',
      'days': [
        {
          'letra': 'A',
          'nome': 'Início',
          'exercises': [
            {
              'nome': 'Flexão na parede',
              'grupoMuscular': 'Peito',
              'equipamento': 'Peso Corporal',
              'volume': '2x8',
              'tempoDescansoSegundos': 60,
              'observacoes': 'Leve'
            }
          ]
        }
      ]
    }, preservePrescription: true);
    final exercises = await (db.select(db.exercises)
          ..where((e) => e.nome.equals('Flexão na parede')))
        .get();
    expect(exercises.map((e) => e.volume), containsAll(['4x12', '2x8']));
  });
}
