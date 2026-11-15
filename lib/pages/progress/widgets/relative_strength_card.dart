import 'package:flutter/material.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';

class RelativeStrengthCard extends StatelessWidget {
  final List<ExerciseLog> logs;
  final List<Exercise> exercises;
  final double userWeight;

  const RelativeStrengthCard({
    super.key,
    required this.logs,
    required this.exercises,
    required this.userWeight,
  });

  @override
  Widget build(BuildContext context) {
    if (userWeight <= 0) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Registre seu peso corporal no perfil para calcular seu Índice de Força Relativa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurface, fontSize: 13),
          ),
        ),
      );
    }

    final Map<String, double> best1RMPerGroup = {
      'Peito': 0.0,
      'Perna': 0.0,
      'Costas': 0.0,
    };
    final Map<String, double> bestRaw1RMPerGroup = {
      'Peito': 0.0,
      'Perna': 0.0,
      'Costas': 0.0,
    };
    final Map<String, String> bestExerciseNamePerGroup = {};

    final exerciseMap = {for (final e in exercises) e.id: e};

    for (final log in logs) {
      final ex = exerciseMap[log.exerciseId];
      if (ex == null) continue;

      final equip = ex.equipamento.trim().toLowerCase();
      final nameLower = ex.nome.trim().toLowerCase();
      final muscle = ex.grupoMuscular;

      double factor = 1.0;

      final isLeg =
          muscle == 'Quadríceps' ||
          muscle == 'Posterior' ||
          muscle == 'Panturrilha' ||
          muscle == 'Perna';

      final isMachine =
          equip == 'máquina' ||
          equip == 'maquina' ||
          equip == 'aparelho' ||
          equip == 'articulado' ||
          equip == 'guiado' ||
          nameLower.contains('máquina') ||
          nameLower.contains('maquina') ||
          nameLower.contains('aparelho') ||
          nameLower.contains('leg press') ||
          nameLower.contains('hack');

      final isCableOrSmith =
          equip == 'cabo' ||
          equip == 'smith' ||
          equip == 'polia' ||
          nameLower.contains('cabo') ||
          nameLower.contains('smith') ||
          nameLower.contains('polia');

      if (isLeg && isMachine) {
        factor = 0.6; // 40% de desconto para máquinas de perna
      } else if (isMachine) {
        factor = 0.8; // 20% de desconto para outras máquinas
      } else if (isCableOrSmith) {
        factor = 0.9; // 10% de desconto para polias e Smith
      }

      final String mappedGroup;
      if (isLeg) {
        mappedGroup = 'Perna';
      } else {
        mappedGroup = muscle;
      }

      if (best1RMPerGroup.containsKey(mappedGroup)) {
        final raw1RM = log.peso * (1 + log.repeticoes / 30.0);
        final oneRepMax = raw1RM * factor;
        final currentBest = best1RMPerGroup[mappedGroup] ?? 0.0;
        if (oneRepMax > currentBest) {
          best1RMPerGroup[mappedGroup] = oneRepMax;
          bestRaw1RMPerGroup[mappedGroup] = raw1RM;
          bestExerciseNamePerGroup[mappedGroup] = ex.nome;
        }
      }
    }

    final double peitoRatio = userWeight > 0
        ? (best1RMPerGroup['Peito']! / userWeight)
        : 0.0;
    final double costasRatio = userWeight > 0
        ? (best1RMPerGroup['Costas']! / userWeight)
        : 0.0;
    final double pernaRatio = userWeight > 0
        ? (best1RMPerGroup['Perna']! / userWeight)
        : 0.0;

    double getGroupScore(double ratio, List<double> thresholds) {
      if (ratio <= 0.0) return 1.0;
      final t1 = thresholds[0];
      final t2 = thresholds[1];
      final t3 = thresholds[2];
      if (ratio < t1) {
        return 1.0 + (ratio / t1);
      } else if (ratio < t2) {
        return 2.0 + (ratio - t1) / (t2 - t1);
      } else if (ratio < t3) {
        return 3.0 + (ratio - t2) / (t3 - t2);
      } else {
        return (4.0 + (ratio - t3) / (t3 * 0.5)).clamp(4.0, 5.0);
      }
    }

    final peitoScore = getGroupScore(peitoRatio, const [0.5, 0.9, 1.3]);
    final costasScore = getGroupScore(costasRatio, const [0.5, 0.8, 1.2]);
    final pernaScore = getGroupScore(pernaRatio, const [0.8, 1.3, 1.8]);

    final overallScore = (peitoScore + costasScore + pernaScore) / 3.0;
    final totalBest1RM = best1RMPerGroup.values.fold<double>(
      0.0,
      (sum, val) => sum + val,
    );

    String levelName = 'Iniciante';
    double nextLevelScore = 2.0;
    double prevLevelScore = 1.0;
    Color levelColor = Colors.blueAccent;
    bool isMaxLevel = false;

    if (overallScore < 2.0) {
      levelName = 'Iniciante (Nível 1)';
      nextLevelScore = 2.0;
      prevLevelScore = 1.0;
      levelColor = Colors.blueAccent;
    } else if (overallScore < 3.0) {
      levelName = 'Intermediário (Nível 2)';
      nextLevelScore = 3.0;
      prevLevelScore = 2.0;
      levelColor = AppColors.primaryLight;
    } else if (overallScore < 4.0) {
      levelName = 'Avançado (Nível 3)';
      nextLevelScore = 4.0;
      prevLevelScore = 3.0;
      levelColor = AppColors.success;
    } else {
      levelName = 'Elite (Nível 4)';
      nextLevelScore = 4.0;
      prevLevelScore = 4.0;
      levelColor = Colors.amber;
      isMaxLevel = true;
    }

    final ratioProgress = isMaxLevel
        ? 1.0
        : (nextLevelScore > prevLevelScore
              ? ((overallScore - prevLevelScore) /
                        (nextLevelScore - prevLevelScore))
                    .clamp(0.0, 1.0)
              : 1.0);

    return GestureDetector(
      onTap: () {
        _showRelativeStrengthLevelsDialog(
          context: context,
          overallScore: overallScore,
          peitoScore: peitoScore,
          costasScore: costasScore,
          pernaScore: pernaScore,
          peitoRatio: peitoRatio,
          costasRatio: costasRatio,
          pernaRatio: pernaRatio,
          totalBest1RM: totalBest1RM,
          userWeight: userWeight,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressSectionLabel('FORÇA RELATIVA (BENCHMARK)'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: levelColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Índice Geral: ${overallScore.toStringAsFixed(2)} / 4.00 (Média de Níveis)',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Nível ${overallScore.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratioProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(levelColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nível ${prevLevelScore.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: context.onSurface),
                  ),
                  if (isMaxLevel)
                    const Text(
                      'Nível Máximo Atingido 👑',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    )
                  else
                    Text(
                      'Próximo nível: Nível ${nextLevelScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                ],
              ),
              Divider(color: context.divider, height: 24),
              const Text(
                'MELHORES ESTIMATIVAS DE 1RM (AJUSTADAS):',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _buildMuscleStrengthRow(
                groupName: 'Peito (Empurrar)',
                oneRM: best1RMPerGroup['Peito']!,
                rawOneRM: bestRaw1RMPerGroup['Peito']!,
                exerciseName: bestExerciseNamePerGroup['Peito'],
                bodyWeight: userWeight,
                groupScore: peitoScore,
              ),
              _buildMuscleStrengthRow(
                groupName: 'Costas (Puxar)',
                oneRM: best1RMPerGroup['Costas']!,
                rawOneRM: bestRaw1RMPerGroup['Costas']!,
                exerciseName: bestExerciseNamePerGroup['Costas'],
                bodyWeight: userWeight,
                groupScore: costasScore,
              ),
              _buildMuscleStrengthRow(
                groupName: 'Perna (Agachar)',
                oneRM: best1RMPerGroup['Perna']!,
                rawOneRM: bestRaw1RMPerGroup['Perna']!,
                exerciseName: bestExerciseNamePerGroup['Perna'],
                bodyWeight: userWeight,
                groupScore: pernaScore,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleStrengthRow({
    required String groupName,
    required double oneRM,
    required double rawOneRM,
    required String? exerciseName,
    required double bodyWeight,
    required double groupScore,
  }) {
    final ratio = bodyWeight > 0 ? oneRM / bodyWeight : 0.0;

    String groupLevel = 'Nenhum';
    Color levelColor = Colors.white30;
    if (oneRM > 0) {
      if (groupScore < 2.0) {
        groupLevel = 'Iniciante';
        levelColor = Colors.blueAccent;
      } else if (groupScore < 3.0) {
        groupLevel = 'Intermediário';
        levelColor = AppColors.primaryLight;
      } else if (groupScore < 4.0) {
        groupLevel = 'Avançado';
        levelColor = AppColors.success;
      } else {
        groupLevel = 'Elite';
        levelColor = Colors.amber;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (oneRM > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: levelColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          groupLevel.toUpperCase(),
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (exerciseName != null && oneRM > 0)
                  Text(
                    exerciseName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const Text(
                    'Nenhum registro',
                    style: TextStyle(fontSize: 10, color: Colors.white30),
                  ),
              ],
            ),
          ),
          if (oneRM > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${oneRM.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${ratio.toStringAsFixed(2)}x Peso${rawOneRM > oneRM ? ' (${rawOneRM.toStringAsFixed(0)} kg real)' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            )
          else
            const Text('-', style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }

  void _showRelativeStrengthLevelsDialog({
    required BuildContext context,
    required double overallScore,
    required double peitoScore,
    required double costasScore,
    required double pernaScore,
    required double peitoRatio,
    required double costasRatio,
    required double pernaRatio,
    required double totalBest1RM,
    required double userWeight,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final textColor = context.onBackground;
        final subtextColor = context.onSurface;

        Widget buildLevelItem({
          required String title,
          required String subtitle,
          required String range,
          required String details,
          required Color color,
          required bool isActive,
          required String levelNum,
        }) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? color : context.divider,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isActive ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      levelNum,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: subtextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          color: subtextColor.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      range,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'VOCÊ ESTÁ AQUI',
                          style: TextStyle(
                            color: color,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Níveis de Força',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O Nível de Força é a média dos níveis atingidos em Peito, Costas e Pernas. Cada grupo muscular possui padrões específicos. Para evitar distorções de polias e alavancas, exercícios em máquinas e cabos recebem um fator de correção (ex: polias/smith = -10%, máquinas = -20%, máquinas de perna = -40%).',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.divider.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seu peso: ${userWeight.toStringAsFixed(1)} kg',
                            style: TextStyle(fontSize: 11, color: subtextColor),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Nível Geral',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subtextColor,
                                ),
                              ),
                              Text(
                                overallScore.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Colors.white10),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Peito',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '${peitoRatio.toStringAsFixed(2)}x (Nível ${peitoScore.toStringAsFixed(1)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Costas',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '${costasRatio.toStringAsFixed(2)}x (Nível ${costasScore.toStringAsFixed(1)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Perna',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '${pernaRatio.toStringAsFixed(2)}x (Nível ${pernaScore.toStringAsFixed(1)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                buildLevelItem(
                  title: 'Iniciante (Nível 1)',
                  subtitle: 'Fase de adaptação muscular',
                  range: '< Nível 2',
                  details: 'Peito < 0.5x | Costas < 0.5x | Perna < 0.8x',
                  color: Colors.blueAccent,
                  isActive: overallScore < 2.0,
                  levelNum: '1',
                ),
                buildLevelItem(
                  title: 'Intermediário (Nível 2)',
                  subtitle: 'Base sólida de força',
                  range: 'Nível 2 a 3',
                  details: 'Peito: 0.5x - 0.9x | Costas: 0.5x - 0.8x | Perna: 0.8x - 1.3x',
                  color: AppColors.primaryLight,
                  isActive: overallScore >= 2.0 && overallScore < 3.0,
                  levelNum: '2',
                ),
                buildLevelItem(
                  title: 'Avançado (Nível 3)',
                  subtitle: 'Nível de força expressivo',
                  range: 'Nível 3 a 4',
                  details: 'Peito: 0.9x - 1.3x | Costas: 0.8x - 1.2x | Perna: 1.3x - 1.8x',
                  color: AppColors.success,
                  isActive: overallScore >= 3.0 && overallScore < 4.0,
                  levelNum: '3',
                ),
                buildLevelItem(
                  title: 'Elite (Nível 4)',
                  subtitle: 'Força digna de atletas',
                  range: '≥ Nível 4',
                  details: 'Peito ≥ 1.3x | Costas ≥ 1.2x | Perna ≥ 1.8x',
                  color: Colors.amber,
                  isActive: overallScore >= 4.0,
                  levelNum: '4',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('ENTENDI'),
            ),
          ],
        );
      },
    );
  }
}
