import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/providers/alerts_provider.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileMembershipCard extends StatelessWidget {
  const ProfileMembershipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final membership = ref.watch(membershipSettingsProvider);
        final notifier = ref.read(membershipSettingsProvider.notifier);
        final dateFormatter = DateFormat('dd/MM/yyyy');
        final metrics = ref.watch(membershipMetricsProvider);

        String formatDuration(double hours) {
          final totalMinutes = (hours * 60).round();
          final h = totalMinutes ~/ 60;
          final m = totalMinutes % 60;
          if (h > 0) {
            return '${h}h ${m}m';
          }
          return '${m}m';
        }

        Widget buildMetricRow(
          BuildContext context,
          String label,
          String value, {
          Color? valueColor,
          bool isBold = false,
        }) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.onSurface,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: valueColor ?? context.onBackground,
                ),
              ),
            ],
          );
        }

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
                        color: Colors.amber.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alerta de Mensalidade',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lembretes para pagamento e controle de mensalidade',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: membership.enabled,
                      onChanged: (val) {
                        notifier.updateSettings(enabled: val);
                      },
                      activeThumbColor: AppColors.primaryLight,
                    ),
                  ],
                ),
                if (membership.enabled) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: membership.value > 0
                                  ? membership.value.toStringAsFixed(2)
                                  : '',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'R\$ ',
                                hintText: '0.00',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                  borderSide: BorderSide(
                                    color: context.divider,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                final cleanVal = val.replaceAll(
                                  ',',
                                  '.',
                                );
                                final doubleVal =
                                    double.tryParse(cleanVal) ?? 0.0;
                                notifier.updateSettings(
                                  value: doubleVal,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Período',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: membership.months == 1 ||
                                      membership.months == 12
                                  ? membership.months
                                  : 0,
                              dropdownColor: context.cardColor,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                  borderSide: BorderSide(
                                    color: context.divider,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Mensal'),
                                ),
                                DropdownMenuItem(
                                  value: 12,
                                  child: Text('Anual'),
                                ),
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('Personalizado'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  if (val > 0) {
                                    notifier.updateSettings(
                                      months: val,
                                    );
                                  } else {
                                    notifier.updateSettings(months: 3);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (membership.months != 1 && membership.months != 12) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duração em Meses:',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.onBackground,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: membership.months > 1
                                  ? () => notifier.updateSettings(
                                        months: membership.months - 1,
                                      )
                                  : null,
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                            ),
                            Text(
                              '${membership.months}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => notifier.updateSettings(
                                months: membership.months + 1,
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: membership.nextDueDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        notifier.updateSettings(nextDueDate: picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Próximo Vencimento',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.divider,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormatter.format(
                              membership.nextDueDate,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: context.onBackground,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quando receber alertas?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                      'No dia do vencimento (09:00)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: membership.alertOnDay,
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateSettings(alertOnDay: val);
                      }
                    },
                    activeColor: AppColors.primaryLight,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text(
                      '3 dias antes (09:00)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: membership.alert3Days,
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateSettings(alert3Days: val);
                      }
                    },
                    activeColor: AppColors.primaryLight,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text(
                      '1 semana antes (09:00)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: membership.alert1Week,
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateSettings(alert1Week: val);
                      }
                    },
                    activeColor: AppColors.primaryLight,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  if (metrics != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.analytics_rounded,
                          color: AppColors.primaryLight,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Métricas do Ciclo Atual',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.onBackground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.divider.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.divider.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          buildMetricRow(
                            context,
                            'Período',
                            '${dateFormatter.format(metrics.cycleStartDate)} - ${dateFormatter.format(metrics.cycleEndDate)}',
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Treinos de Musculação',
                            '${metrics.workoutCount} sessões',
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Treinos de Cárdio',
                            '${metrics.cardioCount} sessões',
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Tempo Total Musculação',
                            formatDuration(metrics.totalDurationHours),
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Tempo Total Cárdio',
                            formatDuration(
                              metrics.totalCardioDurationHours,
                            ),
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Custo Médio por Treino',
                            'R\$ ${metrics.costPerWorkout.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Custo Médio por Cárdio',
                            'R\$ ${metrics.costPerCardio.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Custo Médio por Ida (Geral)',
                            'R\$ ${metrics.costPerVisit.toStringAsFixed(2)}',
                            valueColor: AppColors.primaryLight,
                            isBold: true,
                          ),
                          const Divider(height: 16),
                          buildMetricRow(
                            context,
                            'Custo por Hora (Total)',
                            'R\$ ${metrics.costPerHour.toStringAsFixed(2)}',
                            valueColor: AppColors.primaryLight,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await notifier.markAsPaid();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mensalidade de R\$ ${membership.value.toStringAsFixed(2)} paga! Próximo vencimento: ${dateFormatter.format(ref.read(membershipSettingsProvider).nextDueDate)}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Marcar como Pago'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
