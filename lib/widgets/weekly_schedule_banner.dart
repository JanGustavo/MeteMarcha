import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/database/app_database.dart';
import '../core/providers/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/services/services.dart';
import '../pages/workout/workout_page.dart';

// Provider para controlar se a notificação já foi disparada hoje
final lastNotificationTriggeredProvider = StateProvider<String>((ref) => '');

class WeeklyScheduleBanner extends ConsumerWidget {
  const WeeklyScheduleBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(weeklyScheduleProvider);
    final daysAsync = ref.watch(activeSplitDaysProvider);
    final activeSplitAsync = ref.watch(activeSplitProvider);

    return activeSplitAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (activeSplit) {
        if (activeSplit == null) return const SizedBox.shrink();

        return daysAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (workoutDays) {
            return scheduleAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (schedules) {
                if (schedules.isEmpty) return const SizedBox.shrink();

                // Identifica o dia da semana atual
                final weekdayInt = DateTime.now().weekday;
                final diasSemana = [
                  'Segunda-feira',
                  'Terça-feira',
                  'Quarta-feira',
                  'Quinta-feira',
                  'Sexta-feira',
                  'Sábado',
                  'Domingo',
                ];
                final diaSemanaHoje = diasSemana[weekdayInt - 1];

                // Busca o agendamento de hoje
                final todaySchedule = schedules.firstWhere(
                  (s) => s.diaSemana == diaSemanaHoje,
                  orElse: () => schedules.first,
                );

                final assignedDay = workoutDays.firstWhere(
                  (d) => d.id == todaySchedule.dayId,
                  orElse: () => const WorkoutDay(id: -1, splitId: -1, letra: '', nome: ''),
                );

                final hasWorkout = assignedDay.id != -1;

                // Constrói o título e mensagem
                final String notificationTitle;
                final String notificationMessage;
                if (hasWorkout) {
                  notificationTitle = 'Dia de Treinar! 💪';
                  notificationMessage = '$diaSemanaHoje é dia de treinar ${assignedDay.nome}, vamos dar aquele gás? 🔥';
                } else {
                  notificationTitle = 'Dia de Descanso! 💧';
                  notificationMessage = '$diaSemanaHoje é dia de descanso, mas não esqueça de beber água! 💧';
                }

                // Dispara a notificação nativa do navegador exatamente uma vez por dia
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final lastTriggered = ref.read(lastNotificationTriggeredProvider);
                  if (lastTriggered != todayStr) {
                    NotificationService.showNotification(notificationTitle, notificationMessage);
                    ref.read(lastNotificationTriggeredProvider.notifier).state = todayStr;
                  }
                });

                final isDark = context.isDark;

                // Cores do Gradiente
                final List<Color> gradientColors;
                if (isDark) {
                  gradientColors = hasWorkout
                      ? [
                          AppColors.getWorkoutColor(assignedDay.letra).withValues(alpha: 0.9),
                          AppColors.getWorkoutColor(assignedDay.letra).withValues(alpha: 0.6),
                        ]
                      : [
                          Colors.blueGrey.shade800,
                          Colors.blueGrey.shade900,
                        ];
                } else {
                  gradientColors = hasWorkout
                      ? [
                          AppColors.getWorkoutColor(assignedDay.letra).withValues(alpha: 0.15),
                          AppColors.getWorkoutColor(assignedDay.letra).withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.blueGrey.shade100,
                          Colors.blueGrey.shade50,
                        ];
                }

                // Borda para modo claro
                final Border? border = isDark
                    ? null
                    : Border.all(
                        color: hasWorkout
                            ? AppColors.getWorkoutColor(assignedDay.letra).withValues(alpha: 0.25)
                            : Colors.blueGrey.shade200,
                      );

                // Cor da Sombra
                final Color shadowColor = isDark
                    ? (hasWorkout
                        ? AppColors.getWorkoutColor(assignedDay.letra)
                        : Colors.black).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.05);

                // Estilização de Textos e Ícones
                final Color mainTextColor;
                final Color subTextColor;
                final Color iconColor;
                final Color avatarBgColor;

                if (isDark) {
                  mainTextColor = Colors.white;
                  subTextColor = Colors.white.withValues(alpha: 0.7);
                  iconColor = Colors.white;
                  avatarBgColor = Colors.white.withValues(alpha: 0.2);
                } else {
                  mainTextColor = context.onBackground;
                  subTextColor = context.onSurface;
                  iconColor = hasWorkout
                      ? AppColors.getWorkoutColor(assignedDay.letra)
                      : Colors.blueGrey.shade700;
                  avatarBgColor = hasWorkout
                      ? AppColors.getWorkoutColor(assignedDay.letra).withValues(alpha: 0.12)
                      : Colors.blueGrey.shade200.withValues(alpha: 0.5);
                }

                // Renderiza o card premium
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: border,
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          if (hasWorkout) {
                            final workoutDao = ref.read(workoutDaoProvider);
                            final active = await workoutDao.getActiveSession();

                            if (context.mounted) {
                              if (active != null) {
                                if (active.dayId == assignedDay.id) {
                                  // Retoma o treino ativo de hoje
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutPage(
                                        dayId: assignedDay.id,
                                        dayName: assignedDay.nome,
                                        sessionId: active.id,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Conflito de treino ativo
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      title: const Text('Treino em andamento'),
                                      content: const Text(
                                        'Já existe uma sessão de treino iniciada de outro dia. '
                                        'Deseja cancelá-la para iniciar este novo treino ou prefere retomá-la?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Cancela o anterior e inicia o novo
                                            await workoutDao.cancelSession(active.id);
                                            if (dialogCtx.mounted) {
                                              Navigator.pop(dialogCtx);
                                            }
                                            
                                            final newSessionId = await workoutDao.insertSession(
                                              WorkoutSessionsCompanion.insert(
                                                dayId: Value(assignedDay.id),
                                                data: DateTime.now().toIso8601String(),
                                                status: const Value('em_andamento'),
                                              ),
                                            );
                                            
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => WorkoutPage(
                                                    dayId: assignedDay.id,
                                                    dayName: assignedDay.nome,
                                                    sessionId: newSessionId,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Iniciar Novo'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Retoma o anterior
                                            Navigator.pop(dialogCtx);
                                            final daysMap = ref.read(workoutDaysMapProvider).value;
                                            final activeDayName = daysMap?[active.dayId]?.nome ?? 'Treino';
                                            
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => WorkoutPage(
                                                  dayId: active.dayId!,
                                                  dayName: activeDayName,
                                                  sessionId: active.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Retomar Anterior'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } else {
                                // Cria uma nova sessão
                                final newSessionId = await workoutDao.insertSession(
                                  WorkoutSessionsCompanion.insert(
                                    dayId: Value(assignedDay.id),
                                    data: DateTime.now().toIso8601String(),
                                    status: const Value('em_andamento'),
                                  ),
                                );

                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutPage(
                                        dayId: assignedDay.id,
                                        dayName: assignedDay.nome,
                                        sessionId: newSessionId,
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hoje é dia de descanso! Aproveite para se recuperar. 😴'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              // Ícone correspondente
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: avatarBgColor,
                                child: Icon(
                                  hasWorkout ? Icons.local_fire_department_rounded : Icons.water_drop_rounded,
                                  color: iconColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Texto da Mensagem
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasWorkout ? 'HORA DO SHOW' : 'RECUPERAÇÃO',
                                      style: TextStyle(
                                        color: hasWorkout && !isDark
                                            ? AppColors.getWorkoutColor(assignedDay.letra)
                                            : subTextColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notificationMessage,
                                      style: TextStyle(
                                        color: mainTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
