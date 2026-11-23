import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/core/consistency/weekly_consistency.dart';
import 'package:gym_tracker/core/consistency/consistency_provider.dart';
import 'package:gym_tracker/core/consistency/reward_sharing.dart';
import 'package:gym_tracker/pages/consistency/consistency_page.dart';
import 'package:gym_tracker/pages/consistency/reward_celebration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final reward = EarnedReward(
      id: 'weeks:30',
      title: 'Ritmo constante',
      detail: '30 semanas ativas consecutivas.',
      kind: 'weeks',
      value: '30',
      earnedAt: constDate);
  test('conquista gera imagem quadrada para story', () async {
    final file = await rewardCover(reward);
    expect(
        (await file.readAsBytes()).take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(rewardCaption(reward).runes.length, lessThanOrEqualTo(300));
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 720);
    expect(frame.image.height, 720);
    frame.image.dispose();
    codec.dispose();
  });
  testWidgets(
      'celebração permanece aberta, respeita movimento reduzido e destaca no perfil',
      (tester) async {
    final controller = RewardController();
    await controller.load();
    await controller.add(reward);
    await tester.pumpWidget(ProviderScope(
        overrides: [rewardProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!),
            home: Scaffold(body: RewardCelebration(reward: reward)))));
    await tester.pumpAndSettle();
    expect(find.text('Essa conquista é sua.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Compartilhar no squad'), findsOneWidget);
    final pin = find.text('Destacar no perfil');
    await tester.ensureVisible(pin);
    await tester.tap(pin);
    await tester.pumpAndSettle();
    expect(controller.state.pinned, 'weeks:30');
    expect(find.text('Em destaque no perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'tela mostra sequência atual e melhor histórico de forma separada',
      (tester) async {
    final summary = WeeklyConsistency(
        current: 0,
        best: 30,
        activeWeeks: {'2026-11-02'},
        trainingDays: 1,
        thisWeekDays: 0,
        monday: DateTime(2026, 11, 16));
    await tester.pumpWidget(ProviderScope(overrides: [
      weeklyConsistencyProvider.overrideWithValue(AsyncData(summary))
    ], child: const MaterialApp(home: ConsistencyPage())));
    await tester.pumpAndSettle();
    expect(find.text('Melhor sequência: 30 semanas'), findsOneWidget);
    expect(find.textContaining('Uma semana conta'), findsNothing);
    expect(find.textContaining('Cada semana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'celebração aguarda volta ao início e não reaparece depois de vista',
      (tester) async {
    final controller = RewardController();
    await controller.load();
    final navigator = GlobalKey<NavigatorState>();
    final summary = WeeklyConsistency.calculate(
        [DateTime(2026, 11, 18)], DateTime(2026, 11, 22));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          rewardProvider.overrideWith((ref) => controller),
          weeklyConsistencyProvider.overrideWithValue(AsyncData(summary)),
        ],
        child: MaterialApp(
            navigatorKey: navigator,
            home: Scaffold(
                body: ConsistencyHost(
                    child: Builder(
                        builder: (context) => TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Scaffold(
                                        body: Text('Treino aberto')))),
                            child: const Text('Abrir treino'))))))));
    await tester.pumpAndSettle();
    expect(find.byType(RewardCelebration), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(RewardCelebration), findsNothing);
    await tester.tap(find.text('Abrir treino'));
    await tester.pumpAndSettle();
    await controller.add(EarnedReward(
        id: 'pr:queued',
        title: 'Recorde guardado',
        detail: 'Uma execução registrada',
        kind: 'pr',
        value: '40 kg',
        earnedAt: DateTime(2026, 11, 22)));
    await tester.pumpAndSettle();
    expect(find.byType(RewardCelebration), findsNothing);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Recorde guardado'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(RewardCelebration), findsNothing);
    expect(controller.state.unread, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

final constDate = DateTime(2026, 11, 22);
