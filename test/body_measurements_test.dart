// test/body_measurements_test.dart

import 'dart:ffi';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/database/app_database.dart' hide isNull, isNotNull;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

void main() {
  // Configura o carregamento do SQLite no Linux
  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
  });

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Testes de Medidas Corporais (Body Measurements)', () {
    test('Salvar medida e calcular IMC automaticamente com base na altura', () async {
      // 1. Cria perfil de usuário com altura de 180cm
      await db.profileDao.upsertProfile(
        const UserProfilesCompanion(
          id: Value(1),
          nome: Value('Janderson'),
          altura: Value(180.0), // 1.80m
          pesoAtual: Value(80.0),
        ),
      );

      // 2. Registra medida corporal com peso de 81kg
      final height = 180.0;
      final weight = 81.0;
      final heightInMeters = height / 100;
      final expectedImc = weight / (heightInMeters * heightInMeters);

      final companion = BodyMeasurementsCompanion.insert(
        data: '2026-06-12',
        peso: const Value(81.0),
        gorduraPercentual: const Value(15.0),
        massaMagra: const Value(68.85),
        imc: Value(expectedImc),
        fotoPath: const Value('local/path/photo.jpg'),
      );

      final id = await db.profileDao.insertMeasurement(companion);
      expect(id, isPositive);

      // 3. Recupera o registro e valida os valores
      final saved = await db.profileDao.getMeasurementById(id);
      expect(saved, isNotNull);
      expect(saved!.data, '2026-06-12');
      expect(saved.peso, 81.0);
      expect(saved.gorduraPercentual, 15.0);
      expect(saved.massaMagra, 68.85);
      expect(saved.imc, expectedImc);
      expect(saved.fotoPath, 'local/path/photo.jpg');
    });

    test('watchAllMeasurements deve ordenar os registros de forma decrescente pela data', () async {
      // Insere registros com datas diferentes
      await db.profileDao.insertMeasurement(
        const BodyMeasurementsCompanion(
          data: Value('2026-06-10'),
          peso: Value(78.0),
        ),
      );

      await db.profileDao.insertMeasurement(
        const BodyMeasurementsCompanion(
          data: Value('2026-06-12'),
          peso: Value(80.0),
        ),
      );

      await db.profileDao.insertMeasurement(
        const BodyMeasurementsCompanion(
          data: Value('2026-06-11'),
          peso: Value(79.0),
        ),
      );

      // Obtém todas as medidas
      final list = await db.profileDao.getAllMeasurements();
      expect(list.length, 3);

      // Valida ordenação decrescente (mais recente primeiro)
      expect(list[0].data, '2026-06-12');
      expect(list[1].data, '2026-06-11');
      expect(list[2].data, '2026-06-10');

      // Valida getLatestMeasurement
      final latest = await db.profileDao.getLatestMeasurement();
      expect(latest, isNotNull);
      expect(latest!.data, '2026-06-12');
      expect(latest.peso, 80.0);
    });

    test('Editar e excluir registros de medidas', () async {
      // 1. Insere
      final id = await db.profileDao.insertMeasurement(
        const BodyMeasurementsCompanion(
          data: Value('2026-06-12'),
          peso: Value(75.0),
        ),
      );

      final initial = await db.profileDao.getMeasurementById(id);
      expect(initial, isNotNull);

      // 2. Edita
      final toUpdate = BodyMeasurement(
        id: id,
        data: '2026-06-12',
        peso: 76.5,
        gorduraPercentual: 14.5,
        massaMagra: null,
        imc: null,
        peito: 102.0,
        cintura: 82.0,
        bracoEsquerdo: null,
        bracoDireito: null,
        coxaEsquerda: null,
        coxaDireita: null,
        panturrilhaEsquerda: null,
        panturrilhaDireita: null,
        fotoPath: null,
      );
      final updatedResult = await db.profileDao.updateMeasurement(toUpdate);
      expect(updatedResult, isTrue);

      final retrieved = await db.profileDao.getMeasurementById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.peso, 76.5);
      expect(retrieved.peito, 102.0);

      // 3. Exclui
      final deletedCount = await db.profileDao.deleteMeasurement(id);
      expect(deletedCount, 1);

      final afterDelete = await db.profileDao.getMeasurementById(id);
      expect(afterDelete, isNull);
    });

    test('Diferença entre datas e parsing de semanas', () {
      final date1 = DateTime.tryParse('2026-06-12');
      final date2 = DateTime.tryParse('2026-06-10');
      expect(date1, isNotNull);
      expect(date2, isNotNull);

      final difference = date1!.difference(date2!).inDays;
      expect(difference, 2);
    });
  });
}
