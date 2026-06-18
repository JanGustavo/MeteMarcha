// lib/core/database/database_helper_web.dart
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
    print('Erro ao deletar banco via probe: $e');
  }

  try {
    web.window.indexedDB.deleteDatabase('sqlite3_databases');
    web.window.indexedDB.deleteDatabase(name);
    web.window.indexedDB.deleteDatabase('drift_db/$name');
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao deletar IndexedDB: $e');
  }
}
