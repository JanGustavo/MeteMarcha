/// Calendar weeks start on Monday in the device's local timezone.
DateTime weekMonday(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);
DateTime shiftWeek(DateTime monday, int offset) =>
    DateTime(monday.year, monday.month, monday.day + offset * 7);
String weekDateKey(DateTime monday) =>
    '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
const consistencyMilestones = [1, 3, 6, 10, 12, 20, 30, 52];

class WeeklyConsistency {
  WeeklyConsistency(
      {required this.current,
      required this.best,
      required this.activeWeeks,
      required this.trainingDays,
      required this.thisWeekDays,
      required this.monday});
  final int current, best, trainingDays, thisWeekDays;
  final DateTime monday;
  final Set<String> activeWeeks;
  bool get activeThisWeek => thisWeekDays > 0;
  int? get nextMilestone {
    for (final value in consistencyMilestones) {
      if (value > best) return value;
    }
    return null;
  }

  static WeeklyConsistency calculate(
      Iterable<DateTime> completed, DateTime now) {
    final monday = weekMonday(now);
    final days = <String>{};
    final weekDays = <String, Set<String>>{};
    for (final raw in completed) {
      final local = raw.toLocal();
      if (local.isAfter(now)) continue;
      final day = DateTime(local.year, local.month, local.day);
      final dayKey = weekDateKey(day);
      days.add(dayKey);
      weekDays
          .putIfAbsent(weekDateKey(weekMonday(local)), () => {})
          .add(dayKey);
    }
    final weeks = weekDays.keys.toSet();
    var cursor =
        weeks.contains(weekDateKey(monday)) ? monday : shiftWeek(monday, -1);
    var current = 0;
    while (weeks.contains(weekDateKey(cursor))) {
      current++;
      cursor = shiftWeek(cursor, -1);
    }
    var best = 0, length = 0;
    DateTime? previous;
    final sorted = weeks.map(DateTime.parse).toList()..sort();
    for (final date in sorted) {
      length = previous != null &&
              weekDateKey(shiftWeek(previous, 1)) == weekDateKey(date)
          ? length + 1
          : 1;
      if (length > best) best = length;
      previous = date;
    }
    return WeeklyConsistency(
        current: current,
        best: best,
        activeWeeks: weeks,
        trainingDays: days.length,
        thisWeekDays: weekDays[weekDateKey(monday)]?.length ?? 0,
        monday: monday);
  }
}

class EarnedReward {
  const EarnedReward(
      {required this.id,
      required this.title,
      required this.detail,
      required this.kind,
      required this.value,
      required this.earnedAt,
      this.seen = false});
  final String id, title, detail, kind, value;
  final DateTime earnedAt;
  final bool seen;
  EarnedReward viewed() => EarnedReward(
      id: id,
      title: title,
      detail: detail,
      kind: kind,
      value: value,
      earnedAt: earnedAt,
      seen: true);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'kind': kind,
        'value': value,
        'at': earnedAt.toIso8601String(),
        'seen': seen
      };
  factory EarnedReward.fromJson(Map<String, dynamic> json) => EarnedReward(
      id: json['id'],
      title: json['title'],
      detail: json['detail'],
      kind: json['kind'],
      value: json['value'],
      earnedAt: DateTime.parse(json['at']),
      seen: json['seen'] == true);
}
