import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) async {
    if (!await isEnabled()) return false;

    final permitted = await requestPermissions();
    if (!permitted) return false;

    try {
      // Write the workout session
      bool success = await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
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
}
