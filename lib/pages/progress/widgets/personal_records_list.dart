import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class PersonalRecordsList extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;

  const PersonalRecordsList({
    super.key,
    required this.logs,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, ExerciseLog> maxLogs = {};
    for (final log in logs) {
      final existing = maxLogs[log.exerciseId];
      if (existing == null || log.peso > existing.peso) {
        maxLogs[log.exerciseId] = log;
      }
    }

    final exerciseMap = {for (final e in exercises) e.id: e};
    final recordItems =
        maxLogs.entries
            .map((entry) {
              final ex = exerciseMap[entry.key];
              final log = entry.value;
              if (ex == null) return null;

              final oneRepMax = log.peso * (1 + log.repeticoes / 30.0);
              return _RecordItem(
                exerciseName: ex.nome,
                maxWeight: log.peso,
                repsAtMax: log.repeticoes,
                estimated1RM: oneRepMax,
                date: DateTime.tryParse(log.data) ?? DateTime.now(),
                equipamento: ex.equipamento,
              );
            })
            .whereType<_RecordItem>()
            .toList()
          ..sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

    if (recordItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Nenhum recorde registrado ainda.',
            style: TextStyle(color: context.onSurface),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recordItems.length,
      itemBuilder: (context, index) => recordItems[index],
    );
  }
}

class _RecordItem extends StatelessWidget {
  final String exerciseName;
  final double maxWeight;
  final int repsAtMax;
  final double estimated1RM;
  final DateTime date;
  final String? equipamento;

  const _RecordItem({
    required this.exerciseName,
    required this.maxWeight,
    required this.repsAtMax,
    required this.estimated1RM,
    required this.date,
    this.equipamento,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        title: Text(
          exerciseName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'Recorde em: $dateStr',
          style: TextStyle(fontSize: 11, color: context.onSurface),
        ),
        trailing: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            final isBodyweight =
                equipamento?.trim().toLowerCase() == 'peso corporal';
            final textMsg = isBodyweight
                ? '1RM Estimada (Peso Corporal): Para exercícios livres, a carga considerada é a fração do seu peso corporal de fato ativada (ex: Flexão = 65%, Barra = 100%). A 1RM é estimada pela fórmula científica de Epley: Carga Efetiva × (1 + Reps / 30). Este cálculo é amplamente embasado na fisiologia do exercício (Epley, 1985) para estimar com segurança a força máxima sem os riscos de lesão de um teste de carga física real.'
                : '1RM Estimada (One-Rep Max): A carga máxima teórica que você consegue levantar para 1 repetição, estimada pela fórmula clássica de Epley: Peso × (1 + Reps / 30). Validada na literatura científica (Epley, 1985) para prever a capacidade máxima de força a partir de séries submáximas realizadas até a falha.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(textMsg, style: const TextStyle(fontSize: 13)),
                duration: const Duration(seconds: 6),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${maxWeight.toStringAsFixed(1)} kg × $repsAtMax reps',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryLight,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '1RM Est: ${estimated1RM.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
