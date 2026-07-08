// lib/core/database/database_helper_web.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:drift/wasm.dart';

Future<void> deleteWebDatabase(String name) async {
  try {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    for (final existing in probe.existingDatabases) {
      final dbName = existing.$2;
      if (dbName == name || dbName.contains(name)) {
        await probe.deleteDatabase(existing);
      }
    }
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao deletar banco via probe: ${e.toString()}');
  }

  try {
    web.window.indexedDB.deleteDatabase('sqlite3_databases');
    web.window.indexedDB.deleteDatabase(name);
    web.window.indexedDB.deleteDatabase('drift_db/$name');
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao deletar IndexedDB: ${e.toString()}');
  }
}

void saveBackupBytesToLocalStorage(Uint8List bytes) {
  try {
    final base64Bytes = base64Encode(bytes);
    web.window.localStorage.setItem('metemacha_import_db', base64Bytes);
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao salvar no LocalStorage: ${e.toString()}');
  }
}

Uint8List? getBackupBytesFromLocalStorage() {
  try {
    final stored = web.window.localStorage.getItem('metemacha_import_db');
    if (stored != null && stored.isNotEmpty) {
      web.window.localStorage.removeItem('metemacha_import_db');
      return base64Decode(stored);
    }
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao carregar do LocalStorage: ${e.toString()}');
  }
  return null;
}

void reloadWebPage() {
  try {
    web.window.location.reload();
  } catch (_) {}
}
