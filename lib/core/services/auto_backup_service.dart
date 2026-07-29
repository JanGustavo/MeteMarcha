import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoBackupService {
  static const String _prefsKeyLastBackup = 'last_auto_backup_timestamp';

  static Future<void> checkAndRun() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupMs = prefs.getInt(_prefsKeyLastBackup);
      final now = DateTime.now();

      if (lastBackupMs != null) {
        final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
        // Calcula a diferença real de dias
        final difference = now.difference(lastBackupDate).inDays;
        if (difference < 7) {
          return;
        }
      }

      await runBackup();
    } catch (e) {
      debugPrint('Erro ao verificar/rodar backup automático: $e');
    }
  }

  static Future<void> runBackup() async {
    if (kIsWeb) return;

    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/gym_tracker.sqlite');

      if (!await dbFile.exists()) return;

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final backupFileName = 'gym_tracker_auto_backup_$dateStr.sqlite';
      final backupFile = File('${dbFolder.path}/$backupFileName');

      // Copiar o arquivo atual para o backup
      await dbFile.copy(backupFile.path);

      // Atualizar o timestamp no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyLastBackup, now.millisecondsSinceEpoch);

      // Manter apenas os 3 últimos backups automáticos
      final dir = Directory(dbFolder.path);
      final List<FileSystemEntity> files = await dir.list().toList();

      final List<File> backupFiles = [];
      for (final f in files) {
        if (f is File && f.path.contains('gym_tracker_auto_backup_')) {
          backupFiles.add(f);
        }
      }

      // Ordenar decrescente (mais recentes primeiro)
      backupFiles.sort((a, b) => b.path.compareTo(a.path));

      if (backupFiles.length > 3) {
        for (int i = 3; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Erro ao executar backup automático: $e');
    }
  }

  static Future<String?> getLastBackupDateString() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupMs = prefs.getInt(_prefsKeyLastBackup);
    if (lastBackupMs == null) return null;

    final date = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
