import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/progress/workout_session_detail_page.dart';
import 'package:gym_tracker/core/utils/premium_page_route.dart';

const _portugueseMonths = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String _getMonthName(int month) {
  if (month < 1 || month > 12) return '';
  return _portugueseMonths[month - 1];
}

class MonthlyFrequencySliver extends ConsumerWidget {
  const MonthlyFrequencySliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySessionsAsync = ref.watch(monthlySessionsProvider);
    final daysMapAsync = ref.watch(workoutDaysMapProvider);

    return monthlySessionsAsync.when(
      data: (months) {
        if (months.isEmpty) {
          return SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Text(
                    'Nenhum treino concluído ainda.\nInicie e conclua um treino para ver seu histórico mensal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.onSurface, height: 1.5),
                  ),
                ),
              ),
            ),
          );
        }

        return daysMapAsync.when(
          data: (daysMap) {
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final m = months[index];
                final monthName = _getMonthName(m.monthDate.month);
                final year = m.monthDate.year;
                final trainedDaysCount = m.sessions
                    .map((s) {
                      try {
                        return DateTime.parse(s.data).day;
                      } catch (_) {
                        return null;
                      }
                    })
                    .whereType<int>()
                    .toSet()
                    .length;

                final textTrainedDays = trainedDaysCount == 1
                    ? '1 dia treinado'
                    : '$trainedDaysCount dias treinados';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0,
                      title: Text(
                        '$monthName de $year'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      subtitle: Text(
                        textTrainedDays,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurface,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Divider(color: context.divider, height: 16),
                        _MonthCalendarGrid(
                          monthDate: m.monthDate,
                          sessions: m.sessions,
                          daysMap: daysMap,
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'HISTÓRICO DE TREINOS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MonthSessionsList(
                          sessions: m.sessions,
                          daysMap: daysMap,
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: months.length),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (err, _) => SliverToBoxAdapter(
            child: Center(child: Text('Erro ao carregar dados dos dias: $err')),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Center(child: Text('Erro ao carregar frequência mensal: $err')),
      ),
    );
  }
}

class _MonthCalendarGrid extends StatelessWidget {
  final DateTime monthDate;
  final List<WorkoutSession> sessions;
  final Map<int, WorkoutDay> daysMap;

  const _MonthCalendarGrid({
    required this.monthDate,
    required this.sessions,
    required this.daysMap,
  });

  @override
  Widget build(BuildContext context) {
    final year = monthDate.year;
    final month = monthDate.month;
    final totalDays = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(
      year,
      month,
      1,
    ).weekday; // 1 = Monday, 7 = Sunday
    final leadDays = firstWeekday - 1;

    // Group sessions by day of month
    final Map<int, List<WorkoutSession>> daySessions = {};
    for (final s in sessions) {
      try {
        final d = DateTime.parse(s.data);
        daySessions.putIfAbsent(d.day, () => []).add(s);
      } catch (_) {}
    }

    final headers = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: headers
              .map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.onSurface,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadDays + totalDays,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index < leadDays) {
              return const SizedBox.shrink();
            }
            final dayNum = index - leadDays + 1;
            final daySess = daySessions[dayNum] ?? [];
            final hasTrained = daySess.isNotEmpty;

            Color bgColor = context.surfaceColor;
            Color textColor = context.onSurface;
            bool isBold = false;
            Border? border = Border.all(color: context.divider, width: 0.8);

            if (hasTrained) {
              final firstSess = daySess.first;
              final wDay = daysMap[firstSess.dayId];
              bgColor = wDay != null
                  ? AppColors.getWorkoutColor(wDay.letra)
                  : AppColors.primaryLight;
              textColor = Colors.white;
              isBold = true;
              border = null;
            }

            return Tooltip(
              message: hasTrained
                  ? daySess
                        .map((s) {
                          final wDay = daysMap[s.dayId];
                          final name = wDay != null
                              ? 'Dia ${wDay.letra} - ${wDay.nome}'
                              : 'Treino';
                          final dur = s.duracaoSegundos != null
                              ? ' (${s.duracaoSegundos! ~/ 60} min)'
                              : '';
                          return '$name$dur';
                        })
                        .join('\n')
                  : 'Sem treinos',
              child: GestureDetector(
                onTap: hasTrained
                    ? () {
                        _showDaySessionsBottomSheet(
                          context,
                          dayNum,
                          month,
                          year,
                          daySess,
                          daysMap,
                        );
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isBold
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDaySessionsBottomSheet(
    BuildContext context,
    int day,
    int month,
    int year,
    List<WorkoutSession> sessions,
    Map<int, WorkoutDay> daysMap,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Treinos do dia $day/${month.toString().padLeft(2, '0')}/$year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final wDay = daysMap[s.dayId];
                    final name = wDay != null
                        ? 'Dia ${wDay.letra} - ${wDay.nome}'
                        : 'Treino';
                    final color = wDay != null
                        ? AppColors.getWorkoutColor(wDay.letra)
                        : AppColors.primaryLight;
                    final duration = s.duracaoSegundos != null
                        ? '${s.duracaoSegundos! ~/ 60} minutos de duração'
                        : 'Sem duração registrada';

                    return Card(
                      color: context.surfaceColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          child: Text(wDay?.letra ?? 'T'),
                        ),
                        title: Text(name),
                        subtitle: Text(duration),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.onSurface,
                        ),
                        onTap: () {
                          Navigator.pop(ctx); // Fecha o bottom sheet
                          Navigator.of(context).push(
                            PremiumPageRoute(
                              page: WorkoutSessionDetailPage(session: s),
                              transitionType: TransitionType.slideRight,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSessionsList extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final Map<int, WorkoutDay> daysMap;

  const _MonthSessionsList({required this.sessions, required this.daysMap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        final wDay = daysMap[s.dayId];
        final name = wDay != null
            ? 'Dia ${wDay.letra} - ${wDay.nome}'
            : 'Treino';
        final color = wDay != null
            ? AppColors.getWorkoutColor(wDay.letra)
            : AppColors.primaryLight;
        final date = DateTime.tryParse(s.data);
        final dateStr = date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}'
            : '';
        final weekdayStr = date != null
            ? _getWeekdayAbbreviation(date.weekday)
            : '';
        final durationStr = s.duracaoSegundos != null
            ? '${s.duracaoSegundos! ~/ 60} min'
            : '0 min';

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              PremiumPageRoute(
                page: WorkoutSessionDetailPage(session: s),
                transitionType: TransitionType.slideRight,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 65,
                  child: Text(
                    '$dateStr ($weekdayStr)',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: color,
                  child: Text(
                    wDay?.letra ?? 'T',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  durationStr,
                  style: TextStyle(fontSize: 12, color: context.onSurface),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: context.onSurface,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWeekdayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
  }
}

// ─── Extended Progress Widgets ──────────────────────────────────────────────────
