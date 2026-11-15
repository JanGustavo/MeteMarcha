import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class ProfileDataBackupCard extends StatelessWidget {
  const ProfileDataBackupCard({
    super.key,
    required this.lastAutoBackupDate,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.onExportCardioCsv,
    required this.onExportWorkoutCsv,
  });

  final String? lastAutoBackupDate;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final VoidCallback onExportCardioCsv;
  final VoidCallback onExportWorkoutCsv;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.backup_rounded,
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
                        'Dados & Backup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exporte ou importe seus treinos e histórico',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurface,
                        ),
                      ),
                      if (lastAutoBackupDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Último backup automático: $lastAutoBackupDate',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportBackup,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Exportar',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onImportBackup,
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text(
                      'Importar',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportCardioCsv,
                    icon: const Icon(
                      Icons.directions_run_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Cárdio (CSV)',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportWorkoutCsv,
                    icon: const Icon(
                      Icons.fitness_center_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Musculação (CSV)',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
