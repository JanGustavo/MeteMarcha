// lib/core/database/database_helper.dart
import 'dart:typed_data';

Future<void> deleteWebDatabase(String name) async {
  // No-op nas plataformas nativas
}

void saveBackupBytesToLocalStorage(Uint8List bytes) {
  // No-op nas plataformas nativas
}

Uint8List? getBackupBytesFromLocalStorage() {
  return null;
}

void reloadWebPage() {
  // No-op nas plataformas nativas
}

Future<void> downloadCSVWeb(String csvContent, String filename) async {
  // No-op nas plataformas nativas
}

Future<Uint8List?> exportWebDatabase(String name) async {
  return null;
}

void downloadFileWeb(Uint8List bytes, String filename, String mimeType) {
  // No-op nas plataformas nativas
}
