import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class HealthConnectService {
  static const String _prefsKeyEnabled = 'health_connect_enabled';

  // Singleton instance
  static final HealthConnectService instance = HealthConnectService._();
  HealthConnectService._();

  final Health _health = Health();

  static final List<HealthDataType> _types = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static final List<HealthDataAccess> _permissions = [
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
  ];

  /// Checks if Health Connect integration is enabled in settings.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyEnabled) ?? false;
  }

  /// Sets the enabled state of the Health Connect integration.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyEnabled, enabled);
  }

  /// Request authorization from the user.
  Future<bool> requestPermissions() async {
    try {
      final hasPermission = await _health.hasPermissions(_types, permissions: _permissions);
      if (hasPermission == true) {
        return true;
      }
      final success = await _health.requestAuthorization(_types, permissions: _permissions);
      return success;
    } catch (e) {
      debugPrint('Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// Checks if permissions are currently granted.
  Future<bool> hasPermissions() async {
    try {
      final hasPermission = await _health.hasPermissions(_types, permissions: _permissions);
      return hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Syncs a weight and optionally body fat, muscle mass, BMI to Health Connect.
  Future<bool> syncBodyMeasurement({
    required double weightKg,
    double? bodyFatPercent,
    double? bmi,
    required DateTime dateTime,
  }) async {
    // Check if integration is enabled and we have permission
    if (!await isEnabled()) return false;
    
    final permitted = await requestPermissions();
    if (!permitted) return false;

    try {
      bool success = true;

      // Write weight
      success &= await _health.writeHealthData(
        value: weightKg,
        type: HealthDataType.WEIGHT,
        startTime: dateTime,
        endTime: dateTime,
      );

      // Write body fat percentage if present
      if (bodyFatPercent != null && bodyFatPercent > 0) {
        success &= await _health.writeHealthData(
          value: bodyFatPercent,
          type: HealthDataType.BODY_FAT_PERCENTAGE,
          startTime: dateTime,
          endTime: dateTime,
        );
      }

      // Write BMI if present
      if (bmi != null && bmi > 0) {
        try {
          final hasBmiPermission = await _health.hasPermissions([HealthDataType.BODY_MASS_INDEX], permissions: [HealthDataAccess.WRITE]);
          if (hasBmiPermission == true || await _health.requestAuthorization([HealthDataType.BODY_MASS_INDEX], permissions: [HealthDataAccess.WRITE])) {
            success &= await _health.writeHealthData(
              value: bmi,
              type: HealthDataType.BODY_MASS_INDEX,
              startTime: dateTime,
              endTime: dateTime,
            );
          }
        } catch (e) {
          debugPrint('Failed to write BMI: $e');
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error syncing body measurement to Health Connect: $e');
      return false;
    }
  }

  /// Syncs a completed workout session to Health Connect.
  Future<bool> syncWorkout({
    required String title,
    required DateTime start,
    required DateTime end,
    required double estimatedCaloriesBurned,
    HealthWorkoutActivityType activityType = HealthWorkoutActivityType.STRENGTH_TRAINING,
  }) async {
    if (!await isEnabled()) return false;

    final permitted = await requestPermissions();
    if (!permitted) return false;

    try {
      // Write the workout session
      bool success = await _health.writeWorkoutData(
        activityType: activityType,
        start: start,
        end: end,
        totalEnergyBurned: estimatedCaloriesBurned.toInt(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        title: title,
      );

      // Write the active energy burned as a separate data point
      if (estimatedCaloriesBurned > 0) {
        success &= await _health.writeHealthData(
          value: estimatedCaloriesBurned,
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          startTime: start,
          endTime: end,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error syncing workout to Health Connect: $e');
      return false;
    }
  }

  /// Fetches weight and fat percentage points from Health Connect.
  Future<List<HealthDataPoint>> fetchBodyMeasurements({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!await isEnabled()) return [];
    final permitted = await requestPermissions();
    if (!permitted) return [];

    try {
      return await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT, HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      debugPrint('Error fetching body measurements from Health Connect: $e');
      return [];
    }
  }

  /// Sincronização bidirecional de peso e gordura corporal.
  Future<void> syncBidirectionalMeasurements(ProfileDao profileDao) async {
    if (!await isEnabled()) return;
    if (!await hasPermissions()) return;

    try {
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));

      // 1. Buscar dados locais
      final localMeasurements = await profileDao.getAllMeasurements();

      // 2. Enviar medições locais que não estão no Health Connect
      // (Para simplificar e garantir consistência, o Health SDK lida com deduplicação de gravações duplicadas no mesmo timestamp)
      for (final m in localMeasurements) {
        final parsedDate = DateTime.tryParse(m.data);
        if (parsedDate != null && parsedDate.isAfter(oneYearAgo) && m.peso != null) {
          await syncBodyMeasurement(
            weightKg: m.peso!,
            bodyFatPercent: m.gorduraPercentual,
            bmi: m.imc,
            dateTime: parsedDate,
          );
        }
      }

      // 3. Buscar dados do Health Connect
      final cloudPoints = await fetchBodyMeasurements(start: oneYearAgo, end: now);
      if (cloudPoints.isEmpty) return;

      // Agrupar dados de peso e gordura por data (yyyy-MM-dd)
      final Map<String, _BodySyncData> cloudDataByDate = {};
      for (final pt in cloudPoints) {
        final dateStr = '${pt.dateFrom.year}-${pt.dateFrom.month.toString().padLeft(2, '0')}-${pt.dateFrom.day.toString().padLeft(2, '0')}';
        final valObj = pt.value;
        if (valObj is NumericHealthValue) {
          final val = valObj.numericValue.toDouble();
          final data = cloudDataByDate.putIfAbsent(dateStr, () => _BodySyncData());
          if (pt.type == HealthDataType.WEIGHT) {
            data.weight = val;
          } else if (pt.type == HealthDataType.BODY_FAT_PERCENTAGE) {
            data.bodyFat = val;
          }
        }
      }

      // Obter o perfil para calcular IMC
      final profile = await profileDao.getProfile();
      final altura = profile?.altura ?? 0.0;

      // 4. Consolidar na tabela local
      for (final entry in cloudDataByDate.entries) {
        final dateStr = entry.key;
        final syncData = entry.value;

        if (syncData.weight == null && syncData.bodyFat == null) continue;

        // Verificar se já existe local
        final existingLocal = localMeasurements.firstWhere(
          (m) => m.data == dateStr,
          orElse: () => const BodyMeasurement(
            id: -1,
            data: '',
          ),
        );

        if (existingLocal.id == -1) {
          // Não existe localmente: Criar nova medição
          double? imc;
          if (syncData.weight != null && altura > 0) {
            final altMetros = altura / 100.0;
            imc = syncData.weight! / (altMetros * altMetros);
          }

          await profileDao.insertMeasurement(
            BodyMeasurementsCompanion.insert(
              data: dateStr,
              peso: Value(syncData.weight),
              gorduraPercentual: Value(syncData.bodyFat),
              imc: Value(imc),
            ),
          );
        } else {
          // Existe localmente: Atualizar peso/gordura se forem nulos localmente
          bool needsUpdate = false;
          double? updatedPeso = existingLocal.peso;
          double? updatedGordura = existingLocal.gorduraPercentual;
          double? updatedImc = existingLocal.imc;

          if (existingLocal.peso == null && syncData.weight != null) {
            updatedPeso = syncData.weight;
            needsUpdate = true;
            if (altura > 0) {
              final altMetros = altura / 100.0;
              updatedImc = updatedPeso! / (altMetros * altMetros);
            }
          }
          if (existingLocal.gorduraPercentual == null && syncData.bodyFat != null) {
            updatedGordura = syncData.bodyFat;
            needsUpdate = true;
          }

          if (needsUpdate) {
            await profileDao.updateMeasurement(
              existingLocal.copyWith(
                peso: Value(updatedPeso),
                gorduraPercentual: Value(updatedGordura),
                imc: Value(updatedImc),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error during bidirectional measurements sync: $e');
    }
  }
}

class _BodySyncData {
  double? weight;
  double? bodyFat;
}
