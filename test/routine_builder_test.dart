import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/core/database/app_database.dart'
    hide isNull, isNotNull;
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/pages/setup/routine_builder_page.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

void main() {
  testWidgets('rotina pode ser nomeada e receber exercício sem JSON',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    open.overrideFor(OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() => db.select(db.exercises).get());
    int? created;
    await tester.pumpWidget(ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
            home: RoutineBuilderPage(
                focus: 'calistenia', onCreated: (id) => created = id))));
    await tester.pumpAndSettle();
    final name = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Nome da rotina');
    await tester.enterText(name, 'Em casa');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 dias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 dia').last);
    await tester.pumpAndSettle();
    final add = find.text('Adicionar exercício do catálogo');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    final search = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.labelText == 'Buscar exercício ou grupo muscular');
    await tester.enterText(search, 'parede');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flexão na parede'));
    await tester.pumpAndSettle();
    expect(find.text('1. Flexão na parede'), findsOneWidget);
    final create = find.text('Criar rotina');
    await tester.scrollUntilVisible(create, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.runAsync(() async {
      await (tester.state(find.byType(RoutineBuilderPage)) as dynamic).save();
    });
    await tester.pump(const Duration(milliseconds: 500));
    final result = await tester.runAsync(() => db
        .customSelect(
            'SELECT e.training_mode,e.link FROM exercises e JOIN workout_day_exercises w ON w.exercise_id=e.id JOIN workout_days d ON d.id=w.day_id JOIN workout_splits s ON s.id=d.split_id WHERE s.nome=?',
            variables: [const Variable('Em casa')])
        .get()
        .timeout(const Duration(seconds: 5)));
    expect(created, isNotNull);
    expect(result, isNotEmpty);
    expect(result!.first.read<String>('training_mode'), 'calistenia');
    expect(result.first.readNullable<String>('link'), isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
