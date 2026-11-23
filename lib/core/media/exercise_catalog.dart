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
    return text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static bool compatibleEquipment(
      String equipment, Map<String, dynamic> entry) {
    final supplied = normalize(equipment);
    final expected = normalize(entry['equipment']);
    if (supplied.isEmpty || supplied == expected) return true;
    const bodyweight = {
      'peso corporal',
      'peso do corpo',
      'corporal',
      'sem equipamento',
      'nenhum',
      'solo',
      'colchonete',
      'bodyweight'
    };
    if (expected == 'peso corporal' &&
        (supplied == 'livre' || bodyweight.contains(supplied))) return true;
    // In bodyweight routines, the bar is support, not an external load.
    return {'pull-up', 'chin-up', 'scapular-pull-up'}.contains(entry['id']) &&
        bodyweight.contains(supplied);
  }

  Map<String, dynamic>? match(String name, String equipment) {
    for (final entry in entries) {
      if (!compatibleEquipment(equipment, entry)) continue;
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
    if ((result['equipamento'] ?? '').toString().trim().isEmpty ||
        normalize('${result['equipamento']}') == 'livre')
      result['equipamento'] = entry['equipment'];
    result['grupoMuscular'] ??= entry['muscle'];
    if ((result['link'] as String?)?.trim().isNotEmpty != true &&
        entry['video'] != null) result['link'] = entry['video']['url'];
    return result;
  }

  String importSummary(Map<String, dynamic> workout) {
    var total = 0, linked = 0;
    for (final day in (workout['days'] ?? workout['dias'] ?? []) as List) {
      for (final exercise
          in (day['exercises'] ?? day['exercicios'] ?? []) as List) {
        total++;
        if ((enrich(Map<String, dynamic>.from(exercise))['link'] ?? '')
            .toString()
            .trim()
            .isNotEmpty) linked++;
      }
    }
    return 'Treino importado · $linked de $total exercícios com vídeo.';
  }
}
