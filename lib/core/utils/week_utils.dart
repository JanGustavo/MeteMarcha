// lib/core/utils/week_utils.dart

class WeekUtils {
  /// Retorna a chave ISO da semana atual no formato "2025-W23".
  /// Semana sempre começa na segunda-feira.
  static String currentWeekKey() {
    final now = DateTime.now();
    return weekKeyFromDate(now);
  }

  static String weekKeyFromDate(DateTime date) {
    // Recua até a segunda-feira da semana
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final week = _isoWeekNumber(monday);
    return '${monday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Formata "2025-W23" → "Semana 23/2025"
  static String formatWeekKey(String key) {
    final parts = key.split('-W');
    if (parts.length != 2) return key;
    return 'Semana ${parts[1]}/${parts[0]}';
  }

  static int _isoWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekday = DateTime(date.year, 1, 1).weekday;
    return ((dayOfYear + weekday - 2) / 7).ceil();
  }

  /// true se ainda não passou da segunda-feira desta semana
  static bool isCurrentWeek(String weekKey) {
    return weekKey == currentWeekKey();
  }

  static String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  static String formatDateWithWeekday(String iso) {
    try {
      final d = DateTime.parse(iso);
      const days = [
        'Segunda-feira',
        'Terça-feira',
        'Quarta-feira',
        'Quinta-feira',
        'Sexta-feira',
        'Sábado',
        'Domingo'
      ];
      final weekday = days[d.weekday - 1];
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ($weekday)';
    } catch (_) {
      return iso;
    }
  }
}
