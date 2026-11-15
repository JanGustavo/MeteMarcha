import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WorkoutActionBar extends StatelessWidget {
  final bool isLast;
  final bool resting;
  final bool hasSets;
  final VoidCallback onSkip;
  final VoidCallback onSalvarSerie;
  final VoidCallback onProximo;

  const WorkoutActionBar({
    super.key,
    required this.isLast,
    required this.resting,
    required this.hasSets,
    required this.onSkip,
    required this.onSalvarSerie,
    required this.onProximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.divider)),
      ),
      child: Row(
        children: [
          // Pular exercício
          OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Pular'),
          ),
          const SizedBox(width: 8),

          // Salvar série
          Expanded(
            child: ElevatedButton.icon(
              onPressed: resting ? null : onSalvarSerie,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Salvar Série'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Próximo / Finalizar
          Expanded(
            child: ElevatedButton(
              onPressed: onProximo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLast ? 'Finalizar' : 'Próximo'),
                  const SizedBox(width: 4),
                  Icon(
                    isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
