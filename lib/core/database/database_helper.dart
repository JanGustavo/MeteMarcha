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
