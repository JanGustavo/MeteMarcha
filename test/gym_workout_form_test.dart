import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/pages/setup/mini_workout_page.dart';
import 'package:gym_tracker/core/services/squad_service.dart';

class DraftAPI extends SquadService {
  Map<String, dynamic>? received;
  @override
  Future<Map<String, dynamic>> request(String method, String path,
      [Map<String, dynamic>? body]) async {
    received = body;
    return {
      'workout': {
        'nome': 'Rotina revisável',
        'tipo': 'CUSTOM',
        'days': [
          for (final letter in ['A', 'B', 'C'])
            {
              'letra': letter,
              'nome': 'Treino $letter',
              'exercises': [
                {
                  'nome': 'Supino reto com halteres',
                  'equipamento': 'Haltere',
                  'volume': '3x10',
                  'tempoDescansoSegundos': 90
                }
              ]
            }
        ]
      }
    };
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('musculação envia duração, divisão e contexto', (tester) async {
    final api = DraftAPI();
    await tester.pumpWidget(ProviderScope(
        child:
            MaterialApp(home: MiniWorkoutPage(focus: 'musculacao', api: api))));
    await tester.pumpAndSettle();
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('10 min'), findsNothing);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '60 min'))
            .selected,
        isTrue);
    final field = find.byType(TextField);
    await tester.scrollUntilVisible(field, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(field, 'Academia cheia, prefiro halteres');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final button = find.text('Gerar sugestão');
    await tester.scrollUntilVisible(button, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(api.received!['minutes'], 60);
    expect(api.received!['split'], 'ABC');
    expect(api.received!['text'], contains('Academia cheia'));
    expect(api.received!['equipment'],
        containsAll(['Máquina', 'Cabo', 'Haltere', 'Barra']));
    await tester.scrollUntilVisible(find.text('C · Treino C'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('C · Treino C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('calistenia mantém sessão curta', (tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: MiniWorkoutPage(focus: 'calistenia'))));
    await tester.pumpAndSettle();
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('60 min'), findsNothing);
    expect(find.text('Divisão de treino'), findsNothing);
    expect(find.text('Máquina'), findsNothing);
  });
}
