import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/providers/alerts_provider.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/database/app_database.dart';

void main() {
  group('Testes de Fatigue Insights', () {
    test('Retorna Sem Dados quando há menos de 5 séries com RPE', () {
      final container = ProviderContainer(
        overrides: [
          allCompletedLogsProvider.overrideWith((ref) {
            return [
              ExerciseLog(
                id: 1,
                sessionId: 1,
                exerciseId: 1,
                repeticoes: 10,
                peso: 50.0,
                serie: 1,
                lado: 'ambos',
                rpe: 8.0,
                data: DateTime.now().toIso8601String(),
                concluido: true,
              ),
            ];
          }),
        ],
      );

      final insight = container.read(fatigueInsightProvider);
      expect(insight.status, 'Sem Dados');
      expect(insight.averageRpe, 0.0);
    });

    test('Calcula Fadiga Ideal para treinos RPE 7-8', () {
      final container = ProviderContainer(
        overrides: [
          allCompletedLogsProvider.overrideWith((ref) {
            final nowStr = DateTime.now().toIso8601String();
            return List.generate(5, (index) => ExerciseLog(
              id: index + 1,
              sessionId: 1,
              exerciseId: 1,
              repeticoes: 8,
              peso: 60.0,
              serie: 1,
              lado: 'ambos',
              rpe: 7.5,
              data: nowStr,
              concluido: true,
            ));
          }),
        ],
      );

      final insight = container.read(fatigueInsightProvider);
      expect(insight.status, 'Ideal');
      expect(insight.averageRpe, 7.5);
      expect(insight.failureRatio, 0.0);
      expect(insight.warnings, isEmpty);
    });

    test('Calcula Fadiga Crítica para treinos com RPE extremamente alto', () {
      final container = ProviderContainer(
        overrides: [
          allCompletedLogsProvider.overrideWith((ref) {
            final nowStr = DateTime.now().toIso8601String();
            return List.generate(5, (index) => ExerciseLog(
              id: index + 1,
              sessionId: 1,
              exerciseId: 1,
              repeticoes: 8,
              peso: 60.0,
              serie: 1,
              lado: 'ambos',
              rpe: 9.5,
              data: nowStr,
              concluido: true,
            ));
          }),
        ],
      );

      final insight = container.read(fatigueInsightProvider);
      expect(insight.status, 'Crítico');
      expect(insight.averageRpe, 9.5);
      expect(insight.failureRatio, 1.0);
      expect(insight.warnings, contains(contains('Muitas séries levadas até a falha')));
    });
  });
}
