// test/database_flow_test.dart

import 'dart:ffi';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/database/app_database.dart' hide isNull, isNotNull;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

void main() {
  // Configura o carregamento do SQLite no Linux para usar a biblioteca de runtime
  // já instalada no sistema, evitando a dependência do pacote libsqlite3-dev
  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
  });

  late AppDatabase db;

  setUp(() async {
    // Abre um banco de dados SQLite em memória para testes isolados
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Testes de Rotinas (Splits)', () {
    test('addSplit deve criar a rotina ABC com dias e exercícios associados', () async {
      // 1. Cria a rotina ABC
      final splitId = await db.workoutDao.addSplit('ABC');
      expect(splitId, isPositive);

      // 2. Verifica se a rotina está ativa e se os dias foram criados
      final activeSplit = await db.workoutDao.getActiveSplit();
      expect(activeSplit, isNotNull);
      expect(activeSplit!.tipo, 'ABC');

      final days = await db.workoutDao.getDaysForSplit(splitId);
      expect(days.length, 3); // ABC tem dias A, B e C
      expect(days[0].letra, 'A');
      expect(days[1].letra, 'B');
      expect(days[2].letra, 'C');

      // 3. Verifica se os exercícios foram vinculados a um dos dias (Ex: Dia A)
      final dayA = days[0];
      final dayAExercises = await db.exerciseDao.getExercisesForDay(dayA.id);
      expect(dayAExercises, isNotEmpty);
      expect(dayAExercises.any((e) => e.nome == 'Supino Reto'), isTrue);
    });

    test('deleteSplit deve remover a rotina e desassociar a agenda semanal sem erros de chave estrangeira', () async {
      // 1. Cria a rotina ABC
      final splitId = await db.workoutDao.addSplit('ABC');
      final days = await db.workoutDao.getDaysForSplit(splitId);
      final dayAId = days[0].id;

      // 2. Associa o dia A na agenda semanal (ex: Segunda-feira)
      final schedules = await db.workoutDao.getWeeklySchedule();
      expect(schedules, isNotEmpty);
      
      final monday = schedules.firstWhere((s) => s.diaSemana == 'Segunda-feira');
      await db.workoutDao.updateWeeklyDay(monday.id, dayAId);

      // Verifica se foi associado
      final updatedSchedules = await db.workoutDao.getWeeklySchedule();
      final updatedMonday = updatedSchedules.firstWhere((s) => s.diaSemana == 'Segunda-feira');
      expect(updatedMonday.dayId, dayAId);

      // 3. Deleta a rotina (isto dispara deleteSplit)
      // O teste garante que o método deleteSplit limpa a chave estrangeira em weekly_schedules antes de deletar
      await expectLater(db.workoutDao.deleteSplit(splitId), completes);

      // 4. Valida se a agenda semanal foi desassociada para 'null' (Descanso)
      final schedulesAfterDelete = await db.workoutDao.getWeeklySchedule();
      final mondayAfterDelete = schedulesAfterDelete.firstWhere((s) => s.diaSemana == 'Segunda-feira');
      expect(mondayAfterDelete.dayId, isNull);

      // 5. Verifica se os dias de treino foram apagados do banco
      final daysAfterDelete = await db.workoutDao.getDaysForSplit(splitId);
      expect(daysAfterDelete, isEmpty);
    });
  });

  group('Testes de Exercícios & Limpeza de Biblioteca', () {
    test('deleteUnusedExercises deve remover apenas os exercícios que não estão em uso', () async {
      // Por padrão, o _seedDatabase insere ~20 exercícios mockados na biblioteca.
      final initialExercises = await db.exerciseDao.getAll();
      expect(initialExercises.length, greaterThan(10));

      // 1. Cria um treino ABC (isto associa alguns exercícios aos dias A, B e C)
      final splitId = await db.workoutDao.addSplit('ABC');
      final days = await db.workoutDao.getDaysForSplit(splitId);
      
      final usedExercises = <int>{};
      for (final day in days) {
        final exs = await db.exerciseDao.getExercisesForDay(day.id);
        usedExercises.addAll(exs.map((e) => e.id));
      }
      expect(usedExercises, isNotEmpty);

      // 2. Executa a limpeza de exercícios não utilizados
      await db.exerciseDao.deleteUnusedExercises();

      // 3. Valida que o número de exercícios diminuiu e que APENAS os em uso restaram
      final remainingExercises = await db.exerciseDao.getAll();
      expect(remainingExercises.length, usedExercises.length);

      final remainingIds = remainingExercises.map((e) => e.id).toSet();
      expect(remainingIds, usedExercises);
    });
  });

  group('Testes de Histórico & Edição (LogDao)', () {
    test('updateLog, updateLogSerie e deleteLog funcionam corretamente', () async {
      // 1. Cria um treino e inicia uma sessão
      final splitId = await db.workoutDao.addSplit('ABC');
      final days = await db.workoutDao.getDaysForSplit(splitId);
      final dayA = days[0];
      final exs = await db.exerciseDao.getExercisesForDay(dayA.id);
      final ex = exs.first;

      // Inicia sessão
      final sessionId = await db.workoutDao.insertSession(WorkoutSessionsCompanion.insert(
        dayId: Value(dayA.id),
        data: DateTime.now().toIso8601String(),
        status: const Value('em_andamento'),
      ));

      // 2. Insere 3 séries (logs) para o exercício
      final log1Id = await db.logDao.insertLog(ExerciseLogsCompanion.insert(
        exerciseId: ex.id,
        sessionId: sessionId,
        data: DateTime.now().toIso8601String(),
        peso: 10.0,
        repeticoes: 10,
        serie: const Value(1),
        lado: const Value('ambos'),
      ));

      final log2Id = await db.logDao.insertLog(ExerciseLogsCompanion.insert(
        exerciseId: ex.id,
        sessionId: sessionId,
        data: DateTime.now().toIso8601String(),
        peso: 12.0,
        repeticoes: 8,
        serie: const Value(2),
        lado: const Value('ambos'),
      ));

      final log3Id = await db.logDao.insertLog(ExerciseLogsCompanion.insert(
        exerciseId: ex.id,
        sessionId: sessionId,
        data: DateTime.now().toIso8601String(),
        peso: 14.0,
        repeticoes: 6,
        serie: const Value(3),
        lado: const Value('ambos'),
      ));

      // 3. Edita o log 2
      await db.logDao.updateLog(log2Id, 15.0, 9, 'Nova obs');
      
      final currentLogs = await db.logDao.getLogsForSession(sessionId);
      final log2 = currentLogs.firstWhere((l) => l.id == log2Id);
      expect(log2.peso, 15.0);
      expect(log2.repeticoes, 9);
      expect(log2.observacoes, 'Nova obs');

      // 4. Deleta o log 2 e re-sequencia as séries posteriores
      await db.logDao.deleteLog(log2Id);

      // Re-sequenciamento
      final exerciseLogs = currentLogs.where((l) => l.exerciseId == ex.id).toList();
      for (final log in exerciseLogs) {
        if (log.id == log2Id) continue;
        if (log.serie > 2) {
          await db.logDao.updateLogSerie(log.id, log.serie - 1);
        }
      }

      final logsAfterDelete = await db.logDao.getLogsForSession(sessionId);
      expect(logsAfterDelete.length, 2);
      
      final log1 = logsAfterDelete.firstWhere((l) => l.id == log1Id);
      final log3 = logsAfterDelete.firstWhere((l) => l.id == log3Id);
      
      expect(log1.serie, 1);
      expect(log3.serie, 2); // De 3, passou a ser série 2
    });
  });
}
