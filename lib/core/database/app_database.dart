// lib/core/database/app_database.dart
//
// IMPORTANTE: após qualquer alteração neste arquivo rode:
//   dart run build_runner build --delete-conflicting-outputs
//
// O arquivo app_database.g.dart é gerado automaticamente.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

export 'package:drift/drift.dart' hide Column, Table;

part 'app_database.g.dart';

// ═══════════════════════════════════════════════════════════════════
// TABLES
// ═══════════════════════════════════════════════════════════════════

/// Exercício base — template reutilizável entre divisões.
/// O peso e as repetições ficam no ExerciseLog para preservar histórico.
@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get nome => text()();

  /// Peito | Costas | Ombro | Tríceps | Bíceps | Perna | Core | Glúteo
  TextColumn get grupoMuscular => text()();

  /// Link YouTube/referência para ver a execução
  TextColumn get link => text().nullable()();

  /// Se true: cada lado é trabalhado separadamente.
  /// Impacta o cálculo de volume: peso × reps × 2 quando lado = 'ambos'.
  BoolColumn get isUnilateral => boolean().withDefault(const Constant(false))();

  /// Livre | Barra | Haltere | Cabo | Máquina | Peso Corporal | Smith
  TextColumn get equipamento => text().withDefault(const Constant('Livre'))();

  /// Tempo de descanso padrão em segundos (padrão 90s)
  IntColumn get tempoDescansoSegundos => integer().withDefault(const Constant(90))();

  /// Volume recomendado (ex: "3x12")
  TextColumn get volume => text().nullable()();

  /// Incrementado a cada sessão concluída (não a cada série).
  IntColumn get vezesFeito => integer().withDefault(const Constant(0))();
}

/// Divisão de treino: ABC / ABCD / ABCDE / Custom
@DataClassName('WorkoutSplit')
class WorkoutSplits extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// ABC | ABCD | ABCDE | CUSTOM
  TextColumn get tipo => text()();

  /// Nome exibido ao usuário
  TextColumn get nome => text()();

  /// Apenas uma divisão pode estar ativa por vez
  BoolColumn get ativo => boolean().withDefault(const Constant(false))();
}

/// Dia dentro de uma divisão: A, B, C…
@DataClassName('WorkoutDay')
class WorkoutDays extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get splitId => integer().references(WorkoutSplits, #id)();

  /// A, B, C, D, E
  TextColumn get letra => text()();

  /// "Peito e Tríceps", "Costas e Bíceps", etc.
  TextColumn get nome => text()();
}

/// Relação dia ↔ exercício com ordenação manual
@DataClassName('WorkoutDayExercise')
class WorkoutDayExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get dayId => integer().references(WorkoutDays, #id)();

  IntColumn get exerciseId => integer().references(Exercises, #id)();

  /// 0-based; controla a ordem de exibição no treino
  IntColumn get ordem => integer()();
}

/// Uma sessão de treino executada (começa ao clicar no dia, termina ao concluir)
@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get dayId => integer().references(WorkoutDays, #id)();

  /// ISO 8601 — "2025-06-07T08:30:00.000"
  TextColumn get data => text()();

  /// em_andamento | concluido | cancelado
  TextColumn get status => text().withDefault(const Constant('em_andamento'))();

  /// Duração total em segundos; preenchido ao concluir
  IntColumn get duracaoSegundos => integer().nullable()();
}

/// Log de uma série de um exercício dentro de uma sessão.
///
/// Exercício unilateral gera:
///   - 1 log com lado='ambos' (simplificado), OU
///   - 2 logs com lado='esquerdo' e 'direito' (granular).
/// O usuário escolhe no momento da execução.
@DataClassName('ExerciseLog')
class ExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get exerciseId => integer().references(Exercises, #id)();

  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();

  TextColumn get data => text()();

  /// kg — pode ser 0 para exercícios de peso corporal
  RealColumn get peso => real()();

  IntColumn get repeticoes => integer()();

  /// O número da série (1, 2, 3...)
  IntColumn get serie => integer().withDefault(const Constant(1))();

  /// ambos | esquerdo | direito
  /// Para bilaterais, sempre 'ambos'.
  TextColumn get lado => text().withDefault(const Constant('ambos'))();

  /// false = série pulada/não realizada (mantém no histórico como ausência)
  BoolColumn get concluido => boolean().withDefault(const Constant(true))();

  /// O equipamento utilizado na execução (pode sobrescrever a recomendação do exercício)
  TextColumn get equipamento => text().nullable()();
}

/// Perfil do usuário (única linha)
@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text().nullable()();
  RealColumn get pesoAtual => real().nullable()();
  RealColumn get altura => real().nullable()();
}

/// Peso corporal registrado por semana (semana começa na segunda-feira)
@DataClassName('WeeklyWeight')
class WeeklyWeights extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// "2025-W23" — chave de semana
  TextColumn get semana => text()();

  RealColumn get peso => real()();

  /// Data exata do registro
  TextColumn get data => text()();
}

/// Planejamento semanal (Quadro de segunda a domingo)
@DataClassName('WeeklySchedule')
class WeeklySchedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Segunda-feira, Terça-feira, etc.
  TextColumn get diaSemana => text()();

  /// ID do dia de treino associado (null = descanso)
  IntColumn get dayId => integer().nullable().references(WorkoutDays, #id)();
}

// ═══════════════════════════════════════════════════════════════════
// DAOs
// ═══════════════════════════════════════════════════════════════════

@DriftAccessor(tables: [Exercises, WorkoutDayExercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  // ── Queries ────────────────────────────────────────────────────

  Stream<List<Exercise>> watchAll() => select(exercises).watch();

  Future<List<Exercise>> getAll() => select(exercises).get();

  Future<Exercise?> getById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  // ── Exercícios de um dia, ordenados ────────────────────────────

  Future<List<Exercise>> getExercisesForDay(int dayId) async {
    final query = select(workoutDayExercises).join([
      innerJoin(
        exercises,
        exercises.id.equalsExp(workoutDayExercises.exerciseId),
      ),
    ])
      ..where(workoutDayExercises.dayId.equals(dayId))
      ..orderBy([OrderingTerm.asc(workoutDayExercises.ordem)]);

    final rows = await query.get();
    return rows.map((r) => r.readTable(exercises)).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────

  Future<int> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  Future<bool> updateExercise(Exercise entry) =>
      update(exercises).replace(entry);

  Future<int> deleteExercise(int id) =>
      (delete(exercises)..where((e) => e.id.equals(id))).go();

  Future<void> incrementVezesFeito(int exerciseId) async {
    await (update(exercises)..where((e) => e.id.equals(exerciseId))).write(
      ExercisesCompanion(
        vezesFeito: Value(
          ((await getById(exerciseId))?.vezesFeito ?? 0) + 1,
        ),
      ),
    );
  }

  // ── Day exercise links ──────────────────────────────────────────

  Future<int> linkExerciseToDay(WorkoutDayExercisesCompanion entry) =>
      into(workoutDayExercises).insert(entry);

  Future<int> unlinkExerciseFromDay(int dayId, int exerciseId) =>
      (delete(workoutDayExercises)
            ..where(
              (de) => de.dayId.equals(dayId) & de.exerciseId.equals(exerciseId),
            ))
          .go();

  Future<void> updateExercisesOrder(List<WorkoutDayExercise> links) async {
    await transaction(() async {
      for (final link in links) {
        await update(workoutDayExercises).replace(link);
      }
    });
  }
}

@DriftAccessor(
  tables: [WorkoutSplits, WorkoutDays, WorkoutDayExercises, WorkoutSessions, ExerciseLogs, WeeklySchedules],
)
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ── Splits ─────────────────────────────────────────────────────

  Stream<List<WorkoutSplit>> watchSplits() => select(workoutSplits).watch();

  Future<WorkoutSplit?> getActiveSplit() =>
      (select(workoutSplits)..where((s) => s.ativo.equals(true)))
          .getSingleOrNull();

  Future<int> insertSplit(WorkoutSplitsCompanion entry) =>
      into(workoutSplits).insert(entry);

  /// Desativa todos e ativa o splitId informado (atomic via transaction)
  Future<void> setActiveSplit(int splitId) async {
    await transaction(() async {
      // Atualiza todas as linhas: chamar `update(table).write(...)` sem `where`
      // para desativar todos os splits.
      await update(workoutSplits)
          .write(const WorkoutSplitsCompanion(ativo: Value(false)));
      await (update(workoutSplits)..where((s) => s.id.equals(splitId)))
          .write(const WorkoutSplitsCompanion(ativo: Value(true)));
    });
  }

  // ── Days ───────────────────────────────────────────────────────

  Future<List<WorkoutDay>> getDaysForSplit(int splitId) => (select(workoutDays)
        ..where((d) => d.splitId.equals(splitId))
        ..orderBy([(d) => OrderingTerm.asc(d.letra)]))
      .get();

  Stream<List<WorkoutDay>> watchDaysForSplit(int splitId) =>
      (select(workoutDays)
            ..where((d) => d.splitId.equals(splitId))
            ..orderBy([(d) => OrderingTerm.asc(d.letra)]))
          .watch();

  Future<WorkoutDay?> getDayById(int id) =>
      (select(workoutDays)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<int> insertDay(WorkoutDaysCompanion entry) =>
      into(workoutDays).insert(entry);

  Future<bool> updateDay(WorkoutDay entry) =>
      update(workoutDays).replace(entry);

  // ── Sessions ───────────────────────────────────────────────────

  Future<int> insertSession(WorkoutSessionsCompanion entry) =>
      into(workoutSessions).insert(entry);

  Future<void> finishSession(int sessionId, int durationSeconds) async {
    await (update(workoutSessions)..where((s) => s.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(
      status: const Value('concluido'),
      duracaoSegundos: Value(durationSeconds),
    ));
  }

  Future<void> cancelSession(int sessionId) async {
    await (update(workoutSessions)..where((s) => s.id.equals(sessionId)))
        .write(const WorkoutSessionsCompanion(status: Value('cancelado')));
  }

  Future<WorkoutSession?> getActiveSession() =>
      (select(workoutSessions)..where((s) => s.status.equals('em_andamento'))..limit(1))
          .getSingleOrNull();

  Stream<WorkoutSession?> watchActiveSession() =>
      (select(workoutSessions)..where((s) => s.status.equals('em_andamento'))..limit(1))
          .watchSingleOrNull();

  Future<void> deleteSession(int sessionId) async {
    await transaction(() async {
      await (delete(exerciseLogs)..where((l) => l.sessionId.equals(sessionId))).go();
      await (delete(workoutSessions)..where((s) => s.id.equals(sessionId))).go();
    });
  }

  Stream<List<WorkoutSession>> watchRecentSessions({int limit = 20}) =>
      (select(workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.data)])
            ..limit(limit))
          .watch();

  Stream<List<WorkoutSession>> watchCompletedSessions() =>
      (select(workoutSessions)
            ..where((s) => s.status.equals('concluido'))
            ..orderBy([(s) => OrderingTerm.desc(s.data)]))
          .watch();


  Future<List<WorkoutSession>> getRecentSessions({int limit = 20}) =>
      (select(workoutSessions)
            ..orderBy([(s) => OrderingTerm.desc(s.data)])
            ..limit(limit))
          .get();

  Future<void> deleteSplit(int splitId) async {
    await transaction(() async {
      final days = await (select(workoutDays)..where((d) => d.splitId.equals(splitId))).get();
      for (final day in days) {
        final sessions = await (select(workoutSessions)..where((s) => s.dayId.equals(day.id))).get();
        for (final session in sessions) {
          await (delete(exerciseLogs)..where((l) => l.sessionId.equals(session.id))).go();
          await (delete(workoutSessions)..where((s) => s.id.equals(session.id))).go();
        }
        await (delete(workoutDayExercises)..where((de) => de.dayId.equals(day.id))).go();
        await (delete(workoutDays)..where((d) => d.id.equals(day.id))).go();
      }
      await (delete(workoutSplits)..where((s) => s.id.equals(splitId))).go();
    });
  }

  Future<int> addSplit(String type) async {
    return await transaction(() async {
      String name = '';
      if (type == 'ABC') {
        name = 'Divisão ABC (Básico)';
      } else if (type == 'ABCD') {
        name = 'Divisão ABCD (Intermediário)';
      } else if (type == 'ABCDE') {
        name = 'Divisão ABCDE (Avançado)';
      } else {
        final existingCustom = await (select(workoutSplits)..where((s) => s.tipo.equals('CUSTOM'))).get();
        name = 'Personalizado ${existingCustom.length + 1}';
      }

      // Se já existir esse tipo (exceto CUSTOM), apenas ativa e retorna
      if (type != 'CUSTOM') {
        final existing = await (select(workoutSplits)..where((s) => s.tipo.equals(type))).getSingleOrNull();
        if (existing != null) {
          await setActiveSplit(existing.id);
          return existing.id;
        }
      }

      // Desativa os outros splits
      await update(workoutSplits).write(const WorkoutSplitsCompanion(ativo: Value(false)));

      final splitId = await into(workoutSplits).insert(
        WorkoutSplitsCompanion.insert(
          tipo: type,
          nome: name,
          ativo: const Value(true),
        ),
      );

      final allExs = await db.exerciseDao.getAll();
      final exerciseMap = {for (var e in allExs) e.nome: e.id};

      if (type == 'ABC') {
        final dayA = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'A', nome: 'Peito, Ombro e Tríceps'),
        );
        final abcAExercises = ['Supino Reto', 'Supino Inclinado', 'Desenvolvimento', 'Elevação Lateral', 'Tríceps Corda'];
        for (var i = 0; i < abcAExercises.length; i++) {
          final exId = exerciseMap[abcAExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayA, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayB = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'B', nome: 'Costas e Bíceps'),
        );
        final abcBExercises = ['Puxada Alta', 'Remada Curvada', 'Remada Unilateral (Serrote)', 'Rosca Direta', 'Rosca Martelo'];
        for (var i = 0; i < abcBExercises.length; i++) {
          final exId = exerciseMap[abcBExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayB, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayC = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'C', nome: 'Perna e Core'),
        );
        final abcCExercises = ['Agachamento Livre', 'Leg Press', 'Cadeira Extensora', 'Mesa Flexora', 'Abdominal Supra'];
        for (var i = 0; i < abcCExercises.length; i++) {
          final exId = exerciseMap[abcCExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayC, exerciseId: exId, ordem: i),
            );
          }
        }
      } else if (type == 'ABCD') {
        final dayA = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'A', nome: 'Peito e Tríceps'),
        );
        final abcdAExercises = ['Supino Reto', 'Supino Inclinado', 'Crucifixo Máquina', 'Tríceps Corda', 'Tríceps Testa'];
        for (var i = 0; i < abcdAExercises.length; i++) {
          final exId = exerciseMap[abcdAExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayA, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayB = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'B', nome: 'Costas e Bíceps'),
        );
        final abcdBExercises = ['Puxada Alta', 'Remada Curvada', 'Remada Unilateral (Serrote)', 'Rosca Direta', 'Rosca Martelo'];
        for (var i = 0; i < abcdBExercises.length; i++) {
          final exId = exerciseMap[abcdBExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayB, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayC = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'C', nome: 'Ombro e Core'),
        );
        final abcdCExercises = ['Desenvolvimento', 'Elevação Lateral', 'Crucifixo Invertido', 'Abdominal Supra', 'Prancha'];
        for (var i = 0; i < abcdCExercises.length; i++) {
          final exId = exerciseMap[abcdCExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayC, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayD = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'D', nome: 'Perna Completa'),
        );
        final abcdDExercises = ['Agachamento Livre', 'Leg Press', 'Cadeira Extensora', 'Mesa Flexora', 'Gêmeos Sentado'];
        for (var i = 0; i < abcdDExercises.length; i++) {
          final exId = exerciseMap[abcdDExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayD, exerciseId: exId, ordem: i),
            );
          }
        }
      } else if (type == 'ABCDE') {
        final dayA = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'A', nome: 'Peito'),
        );
        final abcdeAExercises = ['Supino Reto', 'Supino Inclinado', 'Crucifixo Máquina'];
        for (var i = 0; i < abcdeAExercises.length; i++) {
          final exId = exerciseMap[abcdeAExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayA, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayB = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'B', nome: 'Costas'),
        );
        final abcdeBExercises = ['Puxada Alta', 'Remada Curvada', 'Remada Unilateral (Serrote)'];
        for (var i = 0; i < abcdeBExercises.length; i++) {
          final exId = exerciseMap[abcdeBExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayB, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayC = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'C', nome: 'Ombro'),
        );
        final abcdeCExercises = ['Desenvolvimento', 'Elevação Lateral', 'Crucifixo Invertido'];
        for (var i = 0; i < abcdeCExercises.length; i++) {
          final exId = exerciseMap[abcdeCExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayC, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayD = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'D', nome: 'Perna'),
        );
        final abcdeDExercises = ['Agachamento Livre', 'Leg Press', 'Cadeira Extensora', 'Mesa Flexora', 'Gêmeos Sentado'];
        for (var i = 0; i < abcdeDExercises.length; i++) {
          final exId = exerciseMap[abcdeDExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayD, exerciseId: exId, ordem: i),
            );
          }
        }

        final dayE = await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'E', nome: 'Braços (Bíceps e Tríceps)'),
        );
        final abcdeEExercises = ['Rosca Direta', 'Rosca Martelo', 'Tríceps Corda', 'Tríceps Testa', 'Abdominal Supra'];
        for (var i = 0; i < abcdeEExercises.length; i++) {
          final exId = exerciseMap[abcdeEExercises[i]];
          if (exId != null) {
            await into(workoutDayExercises).insert(
              WorkoutDayExercisesCompanion.insert(dayId: dayE, exerciseId: exId, ordem: i),
            );
          }
        }
      } else if (type == 'CUSTOM') {
        await into(workoutDays).insert(
          WorkoutDaysCompanion.insert(splitId: splitId, letra: 'A', nome: 'Meu Treino A'),
        );
      }

      return splitId;
    });
  }

  // ── Weekly Schedule ──────────────────────────────────────────

  Future<List<WeeklySchedule>> getWeeklySchedule() =>
      select(weeklySchedules).get();

  Stream<List<WeeklySchedule>> watchWeeklySchedule() =>
      select(weeklySchedules).watch();

  Future<void> updateWeeklyDay(int scheduleId, int? dayId) async {
    await (update(weeklySchedules)..where((s) => s.id.equals(scheduleId))).write(
      WeeklySchedulesCompanion(
        dayId: Value(dayId),
      ),
    );
  }

  Future<void> seedWeeklySchedule() async {
    final existing = await getWeeklySchedule();
    if (existing.isEmpty) {
      final dias = [
        'Segunda-feira',
        'Terça-feira',
        'Quarta-feira',
        'Quinta-feira',
        'Sexta-feira',
        'Sábado',
        'Domingo',
      ];
      for (final dia in dias) {
        await into(weeklySchedules).insert(
          WeeklySchedulesCompanion.insert(
            diaSemana: dia,
            dayId: const Value(null),
          ),
        );
      }
    }
  }
}

@DriftAccessor(tables: [ExerciseLogs])
class LogDao extends DatabaseAccessor<AppDatabase> with _$LogDaoMixin {
  LogDao(super.db);

  Future<int> insertLog(ExerciseLogsCompanion entry) =>
      into(exerciseLogs).insert(entry);

  Future<List<ExerciseLog>> getLogsForSession(int sessionId) =>
      (select(exerciseLogs)
        ..where((l) => l.sessionId.equals(sessionId))
        ..orderBy([(l) => OrderingTerm.asc(l.serie)]))
      .get();

  Future<List<ExerciseLog>> getLogsForExerciseLastWeeks(
    int exerciseId, {
    int weeks = 8,
  }) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: weeks * 7)).toIso8601String();
    return (select(exerciseLogs)
          ..where(
            (l) =>
                l.exerciseId.equals(exerciseId) &
                l.data.isBiggerOrEqualValue(cutoff) &
                l.concluido.equals(true),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.data), (l) => OrderingTerm.asc(l.serie)]))
        .get();
  }

  Future<List<ExerciseLog>> getLastLogsForExercise(int exerciseId) async {
    // Busca a sessão mais recente onde esse exercício foi executado e concluído
    final latestLog = await (select(exerciseLogs)
          ..where((l) => l.exerciseId.equals(exerciseId) & l.concluido.equals(true))
          ..orderBy([(l) => OrderingTerm.desc(l.data)])
          ..limit(1))
        .getSingleOrNull();

    if (latestLog == null) return [];

    // Retorna todos os logs (séries) daquela mesma sessão para o exercício
    return (select(exerciseLogs)
          ..where((l) =>
              l.exerciseId.equals(exerciseId) &
              l.sessionId.equals(latestLog.sessionId) &
              l.concluido.equals(true))
          ..orderBy([(l) => OrderingTerm.asc(l.serie)]))
        .get();
  }

  Stream<List<ExerciseLog>> watchExerciseLogs(int exerciseId) {
    return (select(exerciseLogs)
          ..where((l) => l.exerciseId.equals(exerciseId) & l.concluido.equals(true))
          ..orderBy([(l) => OrderingTerm.asc(l.data), (l) => OrderingTerm.asc(l.serie)]))
        .watch();
  }

  Future<int> deleteLog(int logId) =>
      (delete(exerciseLogs)..where((l) => l.id.equals(logId))).go();

  Future<void> deleteLogsForSessionExercise(int sessionId, int exerciseId) =>
      (delete(exerciseLogs)
            ..where((l) => l.sessionId.equals(sessionId) & l.exerciseId.equals(exerciseId)))
          .go();

  // ── Cálculo de volume ──────────────────────────────────────────

  /// Volume mecânico (kg × reps).
  /// Para unilateral com lado='ambos', multiplica por 2
  /// pois os dois lados foram trabalhados com o mesmo peso.
  static double calcularVolume(
    ExerciseLog log, {
    bool isUnilateral = false,
  }) {
    final base = log.peso * log.repeticoes;
    return (isUnilateral && log.lado == 'ambos') ? base * 2 : base;
  }
}

class ProfileDao {
  final AppDatabase db;
  ProfileDao(this.db);

  // ── Profile ────────────────────────────────────────────────────

  Future<UserProfile?> getProfile() =>
      (db.select(db.userProfiles)..limit(1)).getSingleOrNull();

  Stream<UserProfile?> watchProfile() =>
      (db.select(db.userProfiles)..limit(1)).watchSingleOrNull();

  Future<void> upsertProfile(UserProfilesCompanion entry) async {
    final existing = await getProfile();
    if (existing == null) {
      await db.into(db.userProfiles).insert(entry);
    } else {
      await (db.update(db.userProfiles)..where((p) => p.id.equals(existing.id)))
          .write(entry);
    }
  }

  // ── Weekly weights ─────────────────────────────────────────────

  Stream<List<WeeklyWeight>> watchWeeklyWeights() =>
      (db.select(db.weeklyWeights)..orderBy([(w) => OrderingTerm.asc(w.semana)]))
          .watch();

  Future<WeeklyWeight?> getWeightForWeek(String weekKey) =>
      (db.select(db.weeklyWeights)..where((w) => w.semana.equals(weekKey)))
          .getSingleOrNull();

  Future<void> upsertWeeklyWeight(String weekKey, double peso) async {
    final now = DateTime.now().toIso8601String();
    await db.into(db.weeklyWeights).insert(
      WeeklyWeightsCompanion.insert(
        semana: weekKey,
        peso: peso,
        data: now,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════════════════════════════

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutSplits,
    WorkoutDays,
    WorkoutDayExercises,
    WorkoutSessions,
    ExerciseLogs,
    UserProfiles,
    WeeklyWeights,
    WeeklySchedules,
  ],
  daos: [ExerciseDao, WorkoutDao, LogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  late final ProfileDao profileDao = ProfileDao(this);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDatabase(this);
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            // Recria todas as tabelas para garantir compatibilidade com as novas colunas e nomes de tabelas
            await customStatement('PRAGMA foreign_keys = OFF;');
            for (final table in allTables) {
              await m.drop(table);
            }
            await m.createAll();
            await _seedDatabase(this);
            await customStatement('PRAGMA foreign_keys = ON;');
          } else {
            if (from < 4) {
              // Apenas adiciona a coluna de volume sem perder os dados do usuário
              await m.addColumn(exercises, exercises.volume);
            }
            if (from < 5) {
              // Migração para remover a constraint UNIQUE de weekly_weights.semana
              await customStatement('PRAGMA foreign_keys = OFF;');
              await customStatement('ALTER TABLE weekly_weights RENAME TO weekly_weights_old;');
              await m.createTable(weeklyWeights);
              await customStatement(
                'INSERT INTO weekly_weights (id, semana, peso, data) '
                'SELECT id, semana, peso, data FROM weekly_weights_old;'
              );
              await customStatement('DROP TABLE weekly_weights_old;');
              await customStatement('PRAGMA foreign_keys = ON;');
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          final allExs = await select(exercises).get();
          if (allExs.isEmpty) {
            await _seedDatabase(this);
          }
        },
      );

  static QueryExecutor _openConnection() {
    // driftDatabase() detecta automaticamente a plataforma:
    //   Android/iOS → SQLite nativo (via sqlite3_flutter_libs)
    //   Web         → WASM via IndexedDB/OPFS
    return driftDatabase(
      name: 'gym_tracker',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}

Future<void> _seedDatabase(AppDatabase db) async {
  await db.transaction(() async {
    // 1. Cadastra Exercícios
    final exerciseIds = <String, int>{};
    
    final exercisesToInsert = [
      // Peito
      (nome: 'Supino Reto', grupo: 'Peito', equip: 'Barra', unilateral: false, descanso: 120),
      (nome: 'Supino Inclinado', grupo: 'Peito', equip: 'Haltere', unilateral: false, descanso: 90),
      (nome: 'Crucifixo Máquina', grupo: 'Peito', equip: 'Máquina', unilateral: false, descanso: 90),
      // Costas
      (nome: 'Puxada Alta', grupo: 'Costas', equip: 'Máquina', unilateral: false, descanso: 90),
      (nome: 'Remada Curvada', grupo: 'Costas', equip: 'Barra', unilateral: false, descanso: 90),
      (nome: 'Remada Unilateral (Serrote)', grupo: 'Costas', equip: 'Haltere', unilateral: true, descanso: 90),
      // Ombro
      (nome: 'Desenvolvimento', grupo: 'Ombro', equip: 'Haltere', unilateral: false, descanso: 90),
      (nome: 'Elevação Lateral', grupo: 'Ombro', equip: 'Haltere', unilateral: true, descanso: 60),
      (nome: 'Crucifixo Invertido', grupo: 'Ombro', equip: 'Haltere', unilateral: true, descanso: 60),
      // Bíceps
      (nome: 'Rosca Direta', grupo: 'Bíceps', equip: 'Barra', unilateral: false, descanso: 60),
      (nome: 'Rosca Martelo', grupo: 'Bíceps', equip: 'Haltere', unilateral: true, descanso: 60),
      // Tríceps
      (nome: 'Tríceps Corda', grupo: 'Tríceps', equip: 'Cabo', unilateral: false, descanso: 60),
      (nome: 'Tríceps Testa', grupo: 'Tríceps', equip: 'Barra', unilateral: false, descanso: 60),
      // Perna
      (nome: 'Agachamento Livre', grupo: 'Perna', equip: 'Barra', unilateral: false, descanso: 120),
      (nome: 'Leg Press', grupo: 'Perna', equip: 'Máquina', unilateral: false, descanso: 120),
      (nome: 'Cadeira Extensora', grupo: 'Perna', equip: 'Máquina', unilateral: true, descanso: 90),
      (nome: 'Mesa Flexora', grupo: 'Perna', equip: 'Máquina', unilateral: true, descanso: 90),
      (nome: 'Gêmeos Sentado', grupo: 'Perna', equip: 'Máquina', unilateral: false, descanso: 60),
      // Core
      (nome: 'Abdominal Supra', grupo: 'Core', equip: 'Peso Corporal', unilateral: false, descanso: 45),
      (nome: 'Prancha', grupo: 'Core', equip: 'Peso Corporal', unilateral: false, descanso: 45),
    ];

    for (final e in exercisesToInsert) {
      final id = await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          nome: e.nome,
          grupoMuscular: e.grupo,
          equipamento: Value(e.equip),
          isUnilateral: Value(e.unilateral),
          tempoDescansoSegundos: Value(e.descanso),
          vezesFeito: const Value(0),
        ),
      );
      exerciseIds[e.nome] = id;
    }

    final dias = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    for (final dia in dias) {
      await db.into(db.weeklySchedules).insert(
        WeeklySchedulesCompanion.insert(
          diaSemana: dia,
          dayId: const Value(null),
        ),
      );
    }
  });
}
