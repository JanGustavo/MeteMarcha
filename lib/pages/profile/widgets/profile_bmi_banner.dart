import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class ProfileBmiBanner extends StatelessWidget {
  final double? peso;
  final double? altura;
  const ProfileBmiBanner({super.key, this.peso, this.altura});

  @override
  Widget build(BuildContext context) {
    if (peso == null || altura == null || altura! <= 0) {
      return const SizedBox.shrink();
    }
    final alturaM = altura! / 100;
    final imc = peso! / (alturaM * alturaM);
    final String classe;
    final Color cor;

    if (imc < 18.5) {
      classe = 'Abaixo do peso';
      cor = AppColors.info;
    } else if (imc < 25.0) {
      classe = 'Peso normal';
      cor = AppColors.success;
    } else if (imc < 30.0) {
      classe = 'Sobrepeso';
      cor = AppColors.warning;
    } else {
      classe = 'Obesidade';
      cor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, size: 18, color: cor),
          const SizedBox(width: 8),
          Text(
            'IMC: ${imc.toStringAsFixed(1)}',
            style: TextStyle(color: cor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            '· $classe',
            style: TextStyle(color: cor.withValues(alpha: 0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
