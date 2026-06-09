// lib/widgets/weekly_weight_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/providers/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/week_utils.dart';

final weeklyWeightSnoozedProvider = StateProvider<bool>((ref) => false);

class WeeklyWeightBanner extends ConsumerWidget {
  const WeeklyWeightBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialBanner(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      dividerColor: Colors.transparent,
      leading: const Icon(Icons.monitor_weight_rounded,
          color: AppColors.primary, size: 22),
      content: const Text(
        'Peso desta semana ainda não registrado.',
        style: TextStyle(color: AppColors.onBackground, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => _showDialog(context, ref),
          child: const Text('REGISTRAR'),
        ),
        TextButton(
          onPressed: () {
            ref.read(weeklyWeightSnoozedProvider.notifier).state = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lembre-me em 24 horas'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          child: const Text(
            'LEMBRAR EM 24H',
            style: TextStyle(color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Peso da semana'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              WeekUtils.formatWeekKey(WeekUtils.currentWeekKey()),
              style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                hintText: '80.5',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final peso =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (peso == null || peso <= 0) return;

              await ref.read(profileDaoProvider).upsertWeeklyWeight(
                    WeekUtils.currentWeekKey(),
                    peso,
                  );
              // Atualiza também o pesoAtual do perfil
              await ref.read(profileDaoProvider).upsertProfile(
                    UserProfilesCompanion(pesoAtual: Value(peso)),
                  );

              // ignore: use_build_context_synchronously
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
