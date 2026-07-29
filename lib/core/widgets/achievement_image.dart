import 'package:flutter/material.dart';

const Set<String> _supported3dAssets = {
  'bench_press_bronze',
  'bench_press_prata',
  'bench_press_ouro',
  'week_streak_bronze',
  'week_streak_prata',
  'week_streak_ouro',
  'squat_bronze',
  'squat_prata',
  'squat_ouro',
  'deadlift_bronze',
  'deadlift_prata',
  'deadlift_ouro',
  'biceps_bronze',
  'biceps_prata',
  'biceps_ouro',
  'back_bronze',
  'back_prata',
  'back_ouro',
  'calves_bronze',
  'calves_prata',
  'calves_ouro',
  'abs_bronze',
  'abs_prata',
  'abs_ouro',
  'workouts_count_bronze',
  'workouts_count_prata',
  'workouts_count_ouro',
  'total_volume_bronze',
  'total_volume_prata',
  'total_volume_ouro',
  'cardio_distance_bronze',
  'cardio_distance_prata',
  'cardio_distance_ouro',
  'cardio_duration_bronze',
  'cardio_duration_prata',
  'cardio_duration_ouro',
  'cardio_sessions_bronze',
  'cardio_sessions_prata',
  'cardio_sessions_ouro',
  // 'locked', // Descomente quando locked.png estiver disponível
};

class AchievementImage extends StatelessWidget {
  final String achievementId;
  final String? levelName; // Bronze, Prata, Ouro, ou null
  final String fallbackEmoji;
  final double size;
  final bool isLocked;

  const AchievementImage({
    super.key,
    required this.achievementId,
    this.levelName,
    required this.fallbackEmoji,
    required this.size,
    this.isLocked = false,
  });

  /// Verifica se há um asset 3D registrado para este ID e nível.
  static bool isSupported(String achievementId, String? levelName, {bool isLocked = false}) {
    if (isLocked) {
      return _supported3dAssets.contains('locked');
    }
    if (levelName == null) return false;
    final suffix = '_${levelName.toLowerCase()}';
    return _supported3dAssets.contains('$achievementId$suffix');
  }

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      const lockedKey = 'locked';
      if (_supported3dAssets.contains(lockedKey)) {
        return Image.asset(
          'assets/images/achievements/locked.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      } else {
        return Center(
          child: Text(
            '🔒',
            style: TextStyle(fontSize: size * 0.5),
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    final suffix = levelName != null ? '_${levelName!.toLowerCase()}' : '';
    final assetKey = '$achievementId${levelName != null ? '_${levelName!.toLowerCase()}' : ''}';

    if (_supported3dAssets.contains(assetKey)) {
      final assetPath = 'assets/images/achievements/$achievementId$suffix.png';
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              fallbackEmoji,
              style: TextStyle(fontSize: size * 0.5),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    }

    return Center(
      child: Text(
        fallbackEmoji,
        style: TextStyle(fontSize: size * 0.5),
        textAlign: TextAlign.center,
      ),
    );
  }
}
