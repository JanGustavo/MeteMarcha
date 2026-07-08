// test/generate_mock_db.dart
import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Configura o carregamento do SQLite no Linux
  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
  });

  test('Gera o banco de dados de teste das conquistas', () async {
    final dbFile = File('test/metemacha_conquistas_test.sqlite');
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    print('Criando banco de dados de teste em: ${dbFile.path}');
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    // 1. Cadastra o perfil de usuário
    print('Cadastrando perfil do usuário...');
    await db.profileDao.upsertProfile(
      const UserProfilesCompanion(
        id: Value(1),
        nome: Value('Janderson Monstro'),
        altura: Value(180.0),
        pesoAtual: Value(85.0),
      ),
    );

    // 2. Garante que todos os exercícios do seed padrão estão lá
    final allExs = await db.select(db.exercises).get();
    print('Total de exercícios base no banco: ${allExs.length}');

    // 3. Cadastra "Levantamento Terra" se não estiver no seed padrão
    int terraId;
    final terraEx = allExs.where((e) => e.nome.toLowerCase().contains('terra')).toList();
    if (terraEx.isEmpty) {
      print('Cadastrando exercício: Levantamento Terra...');
      terraId = await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          nome: 'Levantamento Terra',
          grupoMuscular: 'Posterior',
          equipamento: const Value('Barra'),
          tempoDescansoSegundos: const Value(120),
          vezesFeito: const Value(0),
        ),
      );
    } else {
      terraId = terraEx.first.id;
    }

    // IDs dos exercícios chave
    final supinoId = allExs.firstWhere((e) => e.nome == 'Supino Reto').id;
    final agachamentoId = allExs.firstWhere((e) => e.nome == 'Agachamento Livre').id;
    final roscaId = allExs.firstWhere((e) => e.nome == 'Rosca Direta').id;
    final puxadaId = allExs.firstWhere((e) => e.nome == 'Puxada Alta').id;
    final gemeosId = allExs.firstWhere((e) => e.nome == 'Gêmeos Sentado').id;
    final abdominalId = allExs.firstWhere((e) => e.nome == 'Abdominal Supra').id;

    // 4. Gera as 105 sessões de treino distribuídas no tempo
    print('Gerando 105 sessões de treino...');
    int totalSessions = 105;
    int sessionsInserted = 0;

    // Distribuição de sessões por semana para testar o streak de 8 semanas
    // Semana 0 a 7: Ativas (streak = 8)
    // Semana 8: Inativa (0 sessões)
    // Semanas 9 a 15: Ativas para completar 105 treinos
    final Map<int, int> sessionsPerWeek = {
      0: 6,
      1: 5,
      2: 5,
      3: 5,
      4: 5,
      5: 5,
      6: 5,
      7: 5,
      8: 0, // Quebra a ofensiva
      9: 9,
      10: 9,
      11: 9,
      12: 9,
      13: 9,
      14: 9,
      15: 10,
    };

    int absSetsLogged = 0;

    for (final entry in sessionsPerWeek.entries) {
      final weekIdx = entry.key;
      final count = entry.value;

      for (int i = 0; i < count; i++) {
        // Calcula data da sessão
        final now = DateTime.now();
        final baseDate = now.subtract(Duration(days: weekIdx * 7));
        final dayOffset = i % 5;
        final sessionDate = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day - baseDate.weekday + 1 + dayOffset,
          10 + i,
          30,
        );

        final sessionId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            data: sessionDate.toIso8601String(),
            status: const Value('concluido'),
            duracaoSegundos: const Value(2700),
            dayId: const Value(null),
          ),
        );

        sessionsInserted++;

        // Inserir logs de volume padrão (25 kg * 10 reps * 3 séries = 750 kg volume)
        // Multiplicado por 105 treinos = 78.75 toneladas (Conquista de Volume: Prata)
        for (int setNum = 1; setNum <= 3; setNum++) {
          await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              exerciseId: supinoId,
              sessionId: sessionId,
              data: sessionDate.toIso8601String(),
              peso: 25.0,
              repeticoes: 10,
              serie: Value(setNum),
              concluido: const Value(true),
              lado: const Value('ambos'),
            ),
          );
        }

        // Inserir logs de abdominal (meta de 120 séries total para abdômen)
        if (absSetsLogged < 120) {
          await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              exerciseId: abdominalId,
              sessionId: sessionId,
              data: sessionDate.toIso8601String(),
              peso: 0.0,
              repeticoes: 15,
              serie: const Value(1),
              concluido: const Value(true),
              lado: const Value('ambos'),
            ),
          );
          absSetsLogged++;

          // Loga mais uma série em algumas sessões para atingir as 120
          if (absSetsLogged < 120 && sessionsInserted <= 15) {
            await db.into(db.exerciseLogs).insert(
              ExerciseLogsCompanion.insert(
                exerciseId: abdominalId,
                sessionId: sessionId,
                data: sessionDate.toIso8601String(),
                peso: 0.0,
                repeticoes: 15,
                serie: const Value(2),
                concluido: const Value(true),
                lado: const Value('ambos'),
              ),
            );
            absSetsLogged++;
          }
        }

        // Inserir recordes de carga (PRs) em sessões específicas do presente (semana 0)
        if (weekIdx == 0) {
          if (i == 0) {
            // Supino Reto: 100 kg * 3 reps -> 1RM = 110 kg (Prata, meta >= 100 kg)
            await db.into(db.exerciseLogs).insert(
              ExerciseLogsCompanion.insert(
                exerciseId: supinoId,
                sessionId: sessionId,
                data: sessionDate.toIso8601String(),
                peso: 100.0,
                repeticoes: 3,
                serie: const Value(4),
                concluido: const Value(true),
                lado: const Value('ambos'),
              ),
            );
            print('Logado PR: Supino 100kg x 3 (1RM = 110kg)');
          } else if (i == 1) {
            // Agachamento Livre: 90 kg * 1 rep -> 1RM = 90 kg (Bronze, meta >= 80 kg)
            await db.into(db.exerciseLogs).insert(
              ExerciseLogsCompanion.insert(
                exerciseId: agachamentoId,
                sessionId: sessionId,
                data: sessionDate.toIso8601String(),
                peso: 90.0,
                repeticoes: 1,
                serie: const Value(4),
                concluido: const Value(true),
                lado: const Value('ambos'),
              ),
            );
            print('Logado PR: Agachamento 90kg x 1 (1RM = 90kg)');
          } else if (i == 2) {
            // Levantamento Terra: 120 kg * 1 rep -> 1RM = 120 kg (Bronze, meta >= 100 kg)
            await db.into(db.exerciseLogs).insert(
              ExerciseLogsCompanion.insert(
                exerciseId: terraId,
                sessionId: sessionId,
                data: sessionDate.toIso8601String(),
                peso: 120.0,
                repeticoes: 1,
                serie: const Value(4),
                concluido: const Value(true),
                lado: const Value('ambos'),
              ),
            );
            print('Logado PR: Levantamento Terra 120kg x 1 (1RM = 120kg)');
          } else if (i == 3) {
            // Rosca Direta (Bíceps): 60 kg * 3 reps -> 1RM = 66 kg (Ouro, meta >= 60 kg)
            await db.into(db.exerciseLogs).insert(
              ExerciseLogsCompanion.insert(
                exerciseId: roscaId,
                sessionId: sessionId,
                data: sessionDate.toIso8601String(),
                peso: 60.0,
                repeticoes: 3,
                serie: const Value(4),
                concluido: const Value(true),
                lado: const Value('ambos'),
            ),
          );
          print('Logado PR: Rosca Direta 60kg x 3 (1RM = 66kg)');
        } else if (i == 4) {
          // Puxada Alta (Costas): 110 kg * 5 reps -> 1RM = 128.3 kg (Ouro, meta >= 120 kg)
          await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              exerciseId: puxadaId,
              sessionId: sessionId,
              data: sessionDate.toIso8601String(),
              peso: 110.0,
              repeticoes: 5,
              serie: const Value(4),
              concluido: const Value(true),
              lado: const Value('ambos'),
            ),
          );
          print('Logado PR: Puxada Alta 110kg x 5 (1RM = 128.3kg)');
        } else if (i == 5) {
          // Gêmeos Sentado (Panturrilha): 90 kg * 1 rep -> 1RM = 90 kg (Prata, meta >= 80 kg)
          await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              exerciseId: gemeosId,
              sessionId: sessionId,
              data: sessionDate.toIso8601String(),
              peso: 90.0,
              repeticoes: 1,
              serie: const Value(4),
              concluido: const Value(true),
              lado: const Value('ambos'),
            ),
          );
          print('Logado PR: Gêmeos Sentado 90kg x 1 (1RM = 90kg)');
        }
      }
    }
  }

  print('Treinos gerados: $sessionsInserted');
  print('Séries de abdômen geradas: $absSetsLogged');

  await db.close();
  print('Geração concluída! Banco de dados salvo em: ${dbFile.path}');
  expect(await dbFile.exists(), isTrue);
  });
}
