import 'dart:convert';

class CalisthenicsMetrics {
  const CalisthenicsMetrics(
      {required this.measure,
      required this.value,
      required this.variation,
      this.loadSource = 'none',
      this.externalKg,
      this.apparatus = '',
      this.assistance = ''});
  final String measure, variation, loadSource, apparatus, assistance;
  final double value;
  final double? externalKg;
  bool get valid =>
      {'reps', 'seconds', 'meters'}.contains(measure) &&
      value.isFinite &&
      value > 0 &&
      value <= 100000 &&
      (measure != 'reps' || value == value.roundToDouble()) &&
      variation.trim().isNotEmpty &&
      variation.length <= 200 &&
      apparatus.length <= 200 &&
      assistance.length <= 200 &&
      {'none', 'measured', 'estimated', 'reported', 'unknown'}
          .contains(loadSource) &&
      ((loadSource == 'unknown' || loadSource == 'none')
          ? externalKg == null
          : externalKg != null &&
              externalKg!.isFinite &&
              externalKg! >= 0 &&
              externalKg! <= 10000) &&
      ((loadSource == 'unknown' || loadSource == 'estimated')
          ? apparatus.trim().isNotEmpty
          : true);
  String get unit =>
      {'reps': 'repetições', 'seconds': 's', 'meters': 'm'}[measure] ?? '';
  String get amount =>
      '${value == value.roundToDouble() ? value.toInt() : value} $unit';
  String get loadLabel => loadSource == 'none'
      ? 'Sem carga externa'
      : loadSource == 'unknown'
          ? 'Carga desconhecida'
          : '${loadSource == 'estimated' ? '≈ ' : ''}$externalKg kg · ${{
              'measured': 'medida',
              'estimated': 'estimada',
              'reported': 'informada'
            }[loadSource]}';
  String get summary =>
      '$amount · $loadLabel${apparatus.isEmpty ? '' : ' · $apparatus'}${assistance.isEmpty ? '' : ' · assistência: $assistance'}';
  String get comparisonKey => jsonEncode([
        measure,
        variation.trim().toLowerCase(),
        loadSource,
        externalKg,
        apparatus.trim().toLowerCase(),
        assistance.trim().toLowerCase()
      ]);
  Map<String, dynamic> toJson() => {
        'measure': measure,
        'value': value,
        'variation': variation,
        'load_source': loadSource,
        'external_kg': externalKg,
        'apparatus': apparatus,
        'assistance': assistance
      };
  String encode() => jsonEncode(toJson());
  static CalisthenicsMetrics? decode(String? raw) {
    try {
      if (raw == null) return null;
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static CalisthenicsMetrics? fromJson(Map<String, dynamic> data) {
    try {
      final result = CalisthenicsMetrics(
          measure: data['measure'],
          value: (data['value'] as num).toDouble(),
          variation: data['variation'],
          loadSource: data['load_source'] ?? 'none',
          externalKg: (data['external_kg'] as num?)?.toDouble(),
          apparatus: data['apparatus'] ?? '',
          assistance: data['assistance'] ?? '');
      return result.valid ? result : null;
    } catch (_) {
      return null;
    }
  }
}
