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
    expect(catalog.entries.where((e) => e['video'] != null).length, 26);
    expect(
        catalog.entries
            .where((e) => e['mini_workout'] == true)
            .every((e) => e['video'] != null),
        isTrue);
    final wall = catalog.enrich(
        {'nome': 'Flexao de bracos na parede', 'equipamento': 'Peso Corporal'});
    expect(wall['catalogId'], 'wall-push-up');
    expect(wall['link'], contains('UezGV10_wUA'));
    expect(
        catalog.enrich({'nome': 'Exercício sem referência'})['link'], isNull);
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
        exported['days'][0]['exercises'][0]['link'], contains('UezGV10_wUA'));
    expect(
        (await (db.select(db.exercises)..where((e) => e.id.equals(old)))
                .getSingle())
            .link,
        isNull);
  });
  test('rótulos de calistenia importados resolvem sem misturar variações',
      () async {
    final catalog = await ExerciseCatalog.load();
    for (final example in [
      ['Prancha', 'Livre', 'plank'],
      ['Flexão de braço', 'Peso do corpo', 'push-up'],
      ['Flexão de braços com joelhos apoiados', 'Livre', 'knee-push-up'],
      ['Barra fixa (pegada pronada)', 'Peso Corporal', 'pull-up'],
      [
        'Elevação de panturrilha em pé',
        'Sem equipamento',
        'standing-calf-raise'
      ],
    ]) {
      final result =
          catalog.enrich({'nome': example[0], 'equipamento': example[1]});
      expect(result['catalogId'], example[2]);
      expect(result['link'], isNotNull);
    }
    expect(catalog.match('Flexão inclinada', 'Livre'), isNull);
    expect(catalog.match('Supino reto com barra', 'Haltere'), isNull);
    expect(catalog.match('Agachamento com barra', 'Barra'), isNull);
  });
  test(
      'treino antigo recebe vídeos ausentes sem reimportar ou alterar prescrição',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final split = await db.workoutDao.insertSplit(
        WorkoutSplitsCompanion.insert(nome: 'Importado', tipo: 'CUSTOM'));
    final day = await db.workoutDao.insertDay(WorkoutDaysCompanion.insert(
        splitId: split, letra: 'A', nome: 'Calistenia'));
    final old = await db.exerciseDao.insertExercise(ExercisesCompanion.insert(
        nome: 'Prancha',
        grupoMuscular: 'Core',
        equipamento: const Value('Livre'),
        volume: const Value('3x30s'),
        tempoDescansoSegundos: const Value(45)));
    final manual = await db.exerciseDao.insertExercise(
        ExercisesCompanion.insert(
            nome: 'Flexão de braço',
            grupoMuscular: 'Peito',
            equipamento: const Value('Livre'),
            link: const Value('https://youtu.be/jNo3GqP-d4I')));
    for (final id in [old, manual]) {
      await db.exerciseDao.linkExerciseToDay(
          WorkoutDayExercisesCompanion.insert(
              dayId: day, exerciseId: id, ordem: id));
    }
    final countBefore = (await db.exerciseDao.getAll()).length;
    final resolved = await db.exerciseDao.getExercisesForDay(day);
    expect(
        resolved.firstWhere((e) => e.id == old).link, contains('uUQKLqKMJSU'));
    final saved = await db.exerciseDao.getById(old);
    expect(saved!.link, isNotNull);
    expect(saved.volume, '3x30s');
    expect(saved.tempoDescansoSegundos, 45);
    expect(saved.equipamento, 'Livre');
    expect((await db.exerciseDao.getById(manual))!.link,
        'https://youtu.be/jNo3GqP-d4I');
    expect((await db.exerciseDao.getAll()).length, countBefore);
  });
}
