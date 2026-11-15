import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/decimal_input_formatter.dart';
import 'package:gym_tracker/core/utils/string_input_formatter.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_bmi_banner.dart';

class ProfileIdentificationCard extends StatelessWidget {
  const ProfileIdentificationCard({
    super.key,
    required this.photoPath,
    required this.nameController,
    required this.heightController,
    required this.weightController,
    required this.saving,
    required this.onPhotoTap,
    required this.onSave,
  });

  final String? photoPath;
  final TextEditingController nameController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final bool saving;
  final VoidCallback onPhotoTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final currentPhotoPath = photoPath;
    Widget avatarChild;
    if (currentPhotoPath == null || currentPhotoPath.isEmpty) {
      avatarChild = const Icon(
        Icons.person_rounded,
        size: 36,
        color: AppColors.primary,
      );
    } else if (currentPhotoPath.startsWith('http') ||
        currentPhotoPath.startsWith('https')) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: Image.network(
          currentPhotoPath,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            size: 36,
            color: AppColors.primary,
          ),
        ),
      );
    } else if (kIsWeb) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: Image.network(
          currentPhotoPath,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
        ),
      );
    } else {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: Image.file(
          File(currentPhotoPath),
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            size: 36,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar / ícone
            GestureDetector(
              onTap: onPhotoTap,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: avatarChild,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nome
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              inputFormatters: [StringInputFormatter()],
            ),
            const SizedBox(height: 12),

            // Altura + Peso
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // IMC (calculado on-the-fly)
            ProfileBmiBanner(
              peso: double.tryParse(weightController.text.replaceAll(',', '.')),
              altura: double.tryParse(heightController.text),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
