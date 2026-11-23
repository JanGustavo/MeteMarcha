import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/core/services/squad_service.dart';
import 'package:gym_tracker/core/consistency/consistency_provider.dart';
import 'package:gym_tracker/core/consistency/weekly_consistency.dart';
import 'package:gym_tracker/pages/consistency/cloud_rewards_card.dart';

class RewardAPI extends SquadService {
  final bodies = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> request(String method, String path,
      [Map<String, dynamic>? body]) async {
    if (method == 'PUT') bodies.add(body!);
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('nuvem só envia após ação explícita e é privada por padrão',
      (tester) async {
    final controller = RewardController();
    await controller.load();
    await controller.add(EarnedReward(
        id: 'weeks:1',
        title: 'Primeira semana',
        detail: 'Uma semana ativa',
        kind: 'weeks',
        value: '1',
        earnedAt: DateTime(2026, 11, 22)));
    await controller.pin('weeks:1');
    final api = RewardAPI();
    await tester.pumpWidget(ProviderScope(
        overrides: [rewardProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: CloudRewardsCard(api: api))))));
    await tester.pumpAndSettle();
    expect(api.bodies, isEmpty);
    final button = find.text('Enviar cópia para a nuvem');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(api.bodies.single['visible_to_squads'], false);
    expect(api.bodies.single['pinned'], 'weeks:1');
    expect(api.bodies.single['records'][0]['at'], endsWith('Z'));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(api.bodies.last['visible_to_squads'], true);
  });
  test(
      'restaurar mistura IDs sem apagar conquista local nem recriar pendências',
      () async {
    final c = RewardController();
    await c.load();
    final local = EarnedReward(
        id: 'local',
        title: 'Local',
        detail: 'Preservar',
        kind: 'pr',
        value: '20',
        earnedAt: DateTime(2026, 11, 22));
    await c.add(local);
    final remote = EarnedReward(
        id: 'cloud',
        title: 'Nuvem',
        detail: 'Restaurada',
        kind: 'weeks',
        value: '10',
        earnedAt: DateTime(2026, 11, 22));
    await c.restore([remote.toJson(), local.toJson()], 'cloud');
    expect(c.state.records.length, 2);
    expect(c.state.showcase!.id, 'cloud');
    expect(c.state.records.firstWhere((r) => r.id == 'cloud').seen, true);
    c.dispose();
  });
}
