import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/workout/widgets/workout_number_field.dart';

class WorkoutSetInput extends StatelessWidget {
  final int serie;
  final TextEditingController pesoCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController obsCtrl;
  final double pesoStep;
  final VoidCallback? onOpenCalculator;

  const WorkoutSetInput({
    super.key,
    required this.serie,
    required this.pesoCtrl,
    required this.repsCtrl,
    required this.obsCtrl,
    required this.pesoStep,
    this.onOpenCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SÉRIE $serie',
              style: TextStyle(
                color: context.onSurface,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onOpenCalculator != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.calculate_rounded,
                  size: 20,
                  color: AppColors.primaryLight,
                ),
                tooltip: 'Calculadora de Anilhas',
                onPressed: onOpenCalculator,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: WorkoutNumberField(
                ctrl: pesoCtrl,
                label: 'Peso (kg)',
                decimal: true,
                step: pesoStep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WorkoutNumberField(
                ctrl: repsCtrl,
                label: 'Repetições',
                step: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: obsCtrl,
          decoration: const InputDecoration(
            labelText: 'Observações (ex: banco 80°, drop set)',
            labelStyle: TextStyle(fontSize: 12),
            prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
