import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gym_tracker/core/calisthenics/calisthenics_metrics.dart';
import 'package:gym_tracker/core/database/app_database.dart'
    hide isNull, isNotNull;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => open.overrideFor(OperatingSystem.linux,
      () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0')));
  test(
      'carga desconhecida permanece nula e unidades/assistência não se misturam',
      () {
    const m = CalisthenicsMetrics(
        measure: 'seconds',
        value: 40,
        variation: 'Prancha',
        loadSource: 'unknown',
        apparatus: 'mochila azul');
    expect(m.valid, isTrue);
    expect(CalisthenicsMetrics.decode(m.encode())!.externalKg, isNull);
    expect(m.summary, contains('desconhecida'));
    const assisted = CalisthenicsMetrics(
        measure: 'seconds',
        value: 40,
        variation: 'Prancha',
        assistance: 'elástico');
    expect(assisted.comparisonKey, isNot(m.comparisonKey));
    const bad =
        CalisthenicsMetrics(measure: 'reps', value: 8.5, variation: 'Flexão');
    expect(bad.valid, isFalse);
    const badLoad = CalisthenicsMetrics(
        measure: 'reps',
        value: 8,
        variation: 'Flexão',
        loadSource: 'unknown',
        externalKg: 0,
        apparatus: 'mochila');
    expect(badLoad.valid, isFalse);
  });
  test('métricas sobrevivem a importação e não entram no cálculo de força',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final split = await db.workoutDao.importWorkoutSplit({
      'nome': 'Calistenia',
      'focus': 'calistenia',
      'days': [
        {
          'letra': 'A',
          'nome': 'Core',
          'exercises': [
            {
              'nome': 'Prancha frontal',
              'grupoMuscular': 'Core',
              'equipamento': 'Peso Corporal',
              'measurementType': 'seconds'
            }
          ]
        }
      ]
    }, preservePrescription: true);
    final exported = await db.workoutDao.exportWorkoutSplit(split);
    final data = exported['days'][0]['exercises'][0];
    expect(data['trainingMode'], 'calistenia');
    expect(data['measurementType'], 'seconds');
    final day = (await db.workoutDao.watchDaysForSplit(split).first).first;
    final exercise = (await db.exerciseDao.getExercisesForDay(day.id)).first;
    final session = await db.into(db.workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
            data: '2026-11-22', status: const Value('concluido')));
    const m = CalisthenicsMetrics(
        measure: 'seconds',
        value: 45,
        variation: 'Prancha',
        loadSource: 'unknown',
        apparatus: 'mochila azul');
    final id = await db.logDao.insertLog(ExerciseLogsCompanion.insert(
        exerciseId: exercise.id,
        sessionId: session,
        data: '2026-11-22',
        peso: 999,
        repeticoes: 8,
        trainingMetrics: Value(m.encode())));
    final saved = (await db.logDao.getLogsForSession(session))
        .firstWhere((l) => l.id == id);
    expect(CalisthenicsMetrics.decode(saved.trainingMetrics)!.amount, '45 s');
    expect(LogDao.calcularVolume(saved), 0);
    expect(await db.logDao.getMax1RMForExercise(exercise.id), 0);
  });
}
