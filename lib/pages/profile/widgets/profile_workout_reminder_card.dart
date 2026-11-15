import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/providers/alerts_provider.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class ProfileWorkoutReminderCard extends StatelessWidget {
  const ProfileWorkoutReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final reminder = ref.watch(workoutReminderSettingsProvider);
        final notifier = ref.read(
          workoutReminderSettingsProvider.notifier,
        );
        final schedules = ref.watch(weeklyScheduleProvider).value ?? [];
        final activeDays = schedules.where((s) => s.dayId != null).toList();

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lembretes de Treino',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Receba avisos 30 minutos antes do horário do treino',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: reminder.enabled,
                      onChanged: (val) {
                        notifier.updateSettings(enabled: val);
                      },
                      activeThumbColor: AppColors.primaryLight,
                    ),
                  ],
                ),
                if (reminder.enabled) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Horário Padrão',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Usado nos dias de treino sem horário específico: ${reminder.globalTime}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        final parts = reminder.globalTime.split(':');
                        final initHour =
                            parts.length == 2 ? int.tryParse(parts[0]) ?? 8 : 8;
                        final initMin =
                            parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: initHour,
                            minute: initMin,
                          ),
                        );
                        if (picked != null) {
                          final timeStr =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          notifier.updateSettings(globalTime: timeStr);
                        }
                      },
                      child: const Text('Alterar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (activeDays.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Nenhum dia de treino agendado no seu planejamento semanal. Configure no seu treino.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: context.onSurface,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Horários por Dia da Semana',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...activeDays.map((schedule) {
                      final dia = schedule.diaSemana;
                      final hasCustom = reminder.customTimes.containsKey(dia);
                      final timeToShow =
                          reminder.customTimes[dia] ?? reminder.globalTime;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        color: context.onSurface.withValues(
                          alpha: 0.03,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: context.divider.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dia,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      hasCustom
                                          ? 'Horário específico: $timeToShow'
                                          : 'Padrão: $timeToShow',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (hasCustom)
                                    IconButton(
                                      onPressed: () =>
                                          notifier.removeDayTime(dia),
                                      icon: const Icon(
                                        Icons.restart_alt_rounded,
                                        size: 20,
                                      ),
                                      tooltip: 'Resetar para o padrão',
                                    ),
                                  TextButton(
                                    onPressed: () async {
                                      final parts = timeToShow.split(
                                        ':',
                                      );
                                      final initHour = parts.length == 2
                                          ? int.tryParse(parts[0]) ?? 8
                                          : 8;
                                      final initMin = parts.length == 2
                                          ? int.tryParse(parts[1]) ?? 0
                                          : 0;
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay(
                                          hour: initHour,
                                          minute: initMin,
                                        ),
                                      );
                                      if (picked != null) {
                                        final timeStr =
                                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                        notifier.updateDayTime(
                                          dia,
                                          timeStr,
                                        );
                                      }
                                    },
                                    child: Text(
                                      hasCustom ? 'Alterar' : 'Definir Horário',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
