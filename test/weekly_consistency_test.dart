import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/core/consistency/weekly_consistency.dart';
import 'package:gym_tracker/core/consistency/consistency_provider.dart';

void main() {
  test('três e seis treinos têm a mesma semana, dias repetidos não inflam', () {
    final now = DateTime(2026, 11, 22, 12);
    final three = WeeklyConsistency.calculate([
      DateTime(2026, 11, 16),
      DateTime(2026, 11, 18),
      DateTime(2026, 11, 20),
      DateTime(2026, 11, 20, 18)
    ], now);
    final six = WeeklyConsistency.calculate(
        List.generate(6, (i) => DateTime(2026, 11, 16 + i)), now);
    expect(three.current, 1);
    expect(six.current, 1);
    expect(three.thisWeekDays, 3);
    expect(three.trainingDays, 3);
  });
  test('semana em andamento preserva sequência, pausa mantém melhor histórico',
      () {
    final dates = [
      DateTime(2026, 10, 26),
      DateTime(2026, 11, 2),
      DateTime(2026, 11, 9)
    ];
    final open = WeeklyConsistency.calculate(dates, DateTime(2026, 11, 22));
    expect(open.current, 3);
    expect(open.activeThisWeek, isFalse);
    expect(open.best, 3);
    final broken = WeeklyConsistency.calculate(dates, DateTime(2026, 11, 23));
    expect(broken.current, 0);
    expect(broken.best, 3);
  });
  test('virada de ano usa semanas de segunda a domingo e ignora futuro', () {
    final summary = WeeklyConsistency.calculate([
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 3),
      DateTime(2027, 1, 6),
      DateTime(2027, 2, 1)
    ], DateTime(2027, 1, 11));
    expect(summary.current, 2);
    expect(summary.best, 2);
    expect(summary.activeWeeks.length, 2);
    expect(summary.trainingDays, 3);
  });
  test('sem sessões mantém estado inicial sem marcos falsos', () {
    final summary = WeeklyConsistency.calculate([], DateTime(2026, 11, 22));
    expect(summary.current, 0);
    expect(summary.best, 0);
    expect(summary.nextMilestone, 1);
  });
  test(
      'medalhas persistem após pausa e pin não se perde em gravações concorrentes',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = RewardController();
    await controller.load();
    final now = DateTime(2026, 11, 22);
    final summary = WeeklyConsistency.calculate(
        List.generate(10, (i) => DateTime(2026, 11, 18 - i * 7)), now);
    final pr = EarnedReward(
        id: 'pr:1',
        title: 'Recorde pessoal',
        detail: '20 kg × 10',
        kind: 'pr',
        value: '26.7 kg',
        earnedAt: now);
    await Future.wait([controller.sync(summary), controller.add(pr)]);
    expect(controller.state.records.where((r) => r.kind == 'weeks').length, 4);
    expect(controller.state.records.any((r) => r.id == 'pr:1'), isTrue);
    await controller.pin('weeks:10');
    await controller.viewed('weeks:10');
    await controller.sync(WeeklyConsistency.calculate([], now));
    final count = controller.state.records.length;
    await controller.sync(summary);
    expect(controller.state.records.length, count);
    controller.dispose();
    final restored = RewardController();
    await restored.load();
    expect(restored.state.showcase?.id, 'weeks:10');
    expect(restored.state.records.length, count);
    expect(restored.state.records.firstWhere((r) => r.id == 'weeks:10').seen,
        isTrue);
    restored.dispose();
  });
}
