import 'dart:convert';
import 'dart:ffi';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/media/exercise_catalog.dart';
import 'package:gym_tracker/core/database/app_database.dart'
    hide isNull, isNotNull;
import 'package:drift/native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => open.overrideFor(OperatingSystem.linux,
      () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0')));
  test('catálogo resolve alias e equipamento sem misturar variações', () async {
    final catalog = await ExerciseCatalog.load();
    expect(catalog.entries.length, 27);
    final wall = catalog.enrich(
        {'nome': 'Flexao de bracos na parede', 'equipamento': 'Peso Corporal'});
    expect(wall['catalogId'], 'wall-push-up');
    expect(wall['link'], contains('t6wxV5jG0Vg'));
    expect(catalog.enrich({'nome': 'Flexão com joelhos apoiados'})['link'],
        isNull);
    expect(
        catalog.enrich(
            {'nome': 'Flexão na parede', 'equipamento': 'Máquina'})['link'],
        isNull);
    expect(
        catalog.enrich({
          'nome': 'Flexão na parede',
          'link': 'https://youtu.be/jNo3GqP-d4I'
        })['link'],
        'https://youtu.be/jNo3GqP-d4I');
    expect(jsonEncode(catalog.entries), isNot(contains('jNo3GqP-d4I')));
  });
  test('importação recebe vídeo sem alterar exercício antigo', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final old = await db.exerciseDao.insertExercise(ExercisesCompanion.insert(
        nome: 'Flexão na parede',
        grupoMuscular: 'Peito',
        equipamento: const Value('Peso Corporal')));
    final id = await db.workoutDao.importWorkoutSplit({
      'nome': 'Início',
      'days': [
        {
          'letra': 'A',
          'nome': 'Treino',
          'exercises': [
            {'nome': 'Flexão na parede', 'equipamento': 'Peso Corporal'}
          ]
        }
      ]
    });
    final exported = await db.workoutDao.exportWorkoutSplit(id);
    expect(
        exported['days'][0]['exercises'][0]['link'], contains('t6wxV5jG0Vg'));
    expect(
        (await (db.select(db.exercises)..where((e) => e.id.equals(old)))
                .getSingle())
            .link,
        isNull);
  });
}
