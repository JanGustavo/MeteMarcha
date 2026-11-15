import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class ProfileOverlayPermissionCard extends StatelessWidget {
  const ProfileOverlayPermissionCard({
    super.key,
    required this.permissionGranted,
    required this.onChanged,
  });

  final bool permissionGranted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_in_picture_alt_rounded,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel Flutuante (Overlay)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exibir controle flutuante sobre outros apps ao minimizar o treino',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: permissionGranted,
              onChanged: onChanged,
              activeThumbColor: AppColors.primaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
