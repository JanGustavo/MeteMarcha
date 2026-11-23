import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_tracker/core/services/squad_service.dart';
import 'package:gym_tracker/pages/squads/squads_page.dart';
import 'package:gym_tracker/pages/squads/workout_report.dart';
import 'package:gym_tracker/core/consistency/weekly_consistency.dart';
import 'package:gym_tracker/core/consistency/reward_sharing.dart';

class FakeStoryService extends SquadService {
  final keys = <String>[];
  final captions = <String>[];
  @override
  Future<Map<String, dynamic>> request(String method, String path,
          [Map<String, dynamic>? body]) async =>
      {'tracks': []};
  @override
  Future<void> publish(
      XFile photo, String caption, Map<String, dynamic>? track, String key,
      {Map<String, dynamic>? report, String? videoUrl}) async {
    keys.add(key);
    captions.add(caption);
    expect(await photo.length(), greaterThan(0));
  }
}

void main() {
  testWidgets(
      'conquista abre rascunho com imagem e legenda e só publica ao confirmar',
      (tester) async {
    final api = FakeStoryService();
    final reward = EarnedReward(
        id: 'weeks:10',
        title: 'Ritmo constante',
        detail: '10 semanas ativas consecutivas.',
        kind: 'weeks',
        value: '10',
        earnedAt: DateTime(2026, 11, 22));
    late XFile cover;
    await tester.runAsync(() async {
      cover = await rewardCover(reward);
    });
    await tester.pumpWidget(MaterialApp(
        home: StoryComposer(
            api: api,
            initialPhoto: cover,
            initialCaption: rewardCaption(reward))));
    await tester.pumpAndSettle();
    expect(api.keys, isEmpty);
    await tester.scrollUntilVisible(find.text('Publicar no squad'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Publicar no squad'));
    await tester.pumpAndSettle();
    expect(api.keys.length, 1);
    expect(api.captions.single, contains('10 semanas'));
  });
  testWidgets(
      'cada rascunho cria chave própria e aceita só relatório sem foto adicional',
      (tester) async {
    final api = FakeStoryService();
    final report = <String, dynamic>{
      'title': 'Treino A',
      'date': '2026-11-21',
      'duration_seconds': 60,
      'sets': [
        {
          'exercise': 'Supino',
          'number': 1,
          'weight_kg': 10,
          'reps': 8,
          'side': 'ambos',
          'completed': true,
          'equipment': '',
          'notes': ''
        }
      ]
    };
    late XFile cover;
    await tester.runAsync(() async {
      cover = await reportCover(report);
    });
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: FilledButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StoryComposer(
                                api: api,
                                initialPhoto: cover,
                                report: report))),
                    child: const Text('Abrir'))))));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Publicar no squad'), 400,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Publicar no squad'));
      await tester.pumpAndSettle();
    }
    expect(api.keys.length, 2);
    expect(api.keys[0], isNot(api.keys[1]));
  });
  testWidgets(
      'visualizador mantém duas publicações do mesmo autor e permite avançar',
      (tester) async {
    dynamic story(String id) => {
          'id': id,
          'author': {'id': 'same', 'display_name': 'Ana'},
          'photo_url': '/v1/stories/$id/photo',
          'visible_until': '2026-11-22T00:00:00Z',
          'caption': id,
          'track': null,
          'reactions': {'counts': {}, 'mine': null}
        };
    await tester.pumpWidget(MaterialApp(
        home: StoryViewer(
            api: SquadService(),
            stories: [story('primeiro'), story('segundo')],
            headers: const {})));
    await tester.pumpAndSettle();
    expect(find.text('Publicação 1 de 2'), findsOneWidget);
    expect(find.text('primeiro'), findsOneWidget);
    await tester.tap(find.byTooltip('Próxima publicação'));
    await tester.pumpAndSettle();
    expect(find.text('Publicação 2 de 2'), findsOneWidget);
    expect(find.text('segundo'), findsOneWidget);
    await tester.tap(find.byTooltip('Publicação anterior'));
    await tester.pumpAndSettle();
    expect(find.text('primeiro'), findsOneWidget);
  });
}
