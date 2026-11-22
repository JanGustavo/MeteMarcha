import 'dart:ffi';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/database/app_database.dart'
    hide isNull, isNotNull;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => open.overrideFor(OperatingSystem.linux,
      () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0')));
  test('divisão compartilhada preserva dias, imagens e referência de vídeo',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.workoutDao.importWorkoutSplit({
      'nome': 'Musculação e calistenia',
      'tipo': 'CUSTOM',
      'days': [
        {
          'letra': 'A',
          'nome': 'Supino',
          'coverImage': 'day-image',
          'exercises': [
            {
              'nome': 'Supino teste',
              'grupoMuscular': 'Peito',
              'link': 'https://youtu.be/jNo3GqP-d4I',
              'referenceImage': 'exercise-image',
              'volume': '2x8'
            }
          ]
        },
        {
          'letra': 'B',
          'nome': 'Calistenia',
          'exercises': [
            {
              'nome': 'Flexão teste',
              'grupoMuscular': 'Peito',
              'equipamento': 'Peso Corporal',
              'volume': '2x8'
            }
          ]
        }
      ]
    }, preservePrescription: true);
    final json = await db.workoutDao.exportWorkoutSplit(id);
    final days = json['days'] as List;
    expect(days.length, 2);
    expect(days.first['coverImage'], 'day-image');
    expect(days.first['exercises'].first['referenceImage'], 'exercise-image');
    expect(
        days.first['exercises'].first['link'], 'https://youtu.be/jNo3GqP-d4I');
    final imported = await db.workoutDao
        .importWorkoutSplit(json, preservePrescription: true);
    expect((await db.workoutDao.exportWorkoutSplit(imported))['days'], days);
  });
  test('migração 14 para 15 preserva a rotina existente', () async {
    final dir = Directory.systemTemp.createTempSync('mm-migration-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final first = AppDatabase.forTesting(NativeDatabase(file));
    final id = await first.workoutDao.insertSplit(
        WorkoutSplitsCompanion.insert(tipo: 'CUSTOM', nome: 'Rotina anterior'));
    await first.close();
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('ALTER TABLE exercises DROP COLUMN reference_image');
    raw.execute('ALTER TABLE workout_days DROP COLUMN cover_image');
    raw.execute('PRAGMA user_version=14');
    raw.dispose();
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final split = await (upgraded.select(upgraded.workoutSplits)
          ..where((s) => s.id.equals(id)))
        .getSingle();
    expect(split.nome, 'Rotina anterior');
    await upgraded.into(upgraded.workoutDays).insert(
        WorkoutDaysCompanion.insert(
            splitId: id,
            letra: 'A',
            nome: 'Dia',
            coverImage: const Value('saved')));
    expect((await upgraded.select(upgraded.workoutDays).get()).first.coverImage,
        'saved');
  });
}
