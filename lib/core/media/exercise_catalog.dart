import 'dart:convert';
import 'package:flutter/services.dart';

class ExerciseCatalog {
  ExerciseCatalog(this.entries);
  final List<Map<String, dynamic>> entries;
  static Future<ExerciseCatalog>? _cached;
  static Future<ExerciseCatalog> load() => _cached ??= _load();
  static Future<ExerciseCatalog> _load() async {
    final data = jsonDecode(await rootBundle
            .loadString('backend/internal/exercisecatalog/catalog.json'))
        as Map<String, dynamic>;
    return ExerciseCatalog((data['exercises'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList());
  }

  static String normalize(String value) {
    var text = value.trim().toLowerCase();
    const accents = 'áàâãéêíóôõúüç';
    const plain = 'aaaaeeiooouuc';
    for (var i = 0; i < accents.length; i++) {
      text = text.replaceAll(accents[i], plain[i]);
    }
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, dynamic>? match(String name, String equipment) {
    for (final entry in entries) {
      if (equipment.isNotEmpty &&
          normalize(equipment) != normalize(entry['equipment'])) continue;
      final aliases = [entry['name'], ...entry['aliases'] as List];
      if (aliases.any((alias) => normalize(alias) == normalize(name)))
        return entry;
    }
    return null;
  }

  // Explicit imported references always win. IDs alone cannot change a variant.
  Map<String, dynamic> enrich(Map<String, dynamic> exercise) {
    final result = Map<String, dynamic>.from(exercise);
    final entry =
        match('${exercise['nome'] ?? ''}', '${exercise['equipamento'] ?? ''}');
    if (entry == null) return result;
    result['catalogId'] = entry['id'];
    if ((result['link'] as String?)?.trim().isNotEmpty != true &&
        entry['video'] != null) result['link'] = entry['video']['url'];
    return result;
  }
}
