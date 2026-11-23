import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/pages/home/widgets/workout_split_selector.dart';

void main() {
  testWidgets('três pontos abrem opções sem selecionar a rotina',
      (tester) async {
    var selections = 0, options = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutSplitSelector(
                name: 'Divisão teste',
                selected: false,
                onSelect: () => selections++,
                onOptions: () => options++))));
    await tester.tap(find.byTooltip('Opções de Divisão teste'));
    expect(options, 1);
    expect(selections, 0);
    await tester.tap(find.text('Divisão teste'));
    expect(selections, 1);
    expect(options, 1);
  });
}
