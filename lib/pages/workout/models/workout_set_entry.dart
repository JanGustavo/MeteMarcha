class WorkoutSetEntry {
  final int? id;
  final int serie;
  final double peso;
  final int reps;
  final String lado;
  final String? equipamento;
  final String? observacoes;
  final double? rpe;
  final int? rir;
  WorkoutSetEntry({
    this.id,
    required this.serie,
    required this.peso,
    required this.reps,
    required this.lado,
    this.equipamento,
    this.observacoes,
    this.rpe,
    this.rir,
  });
}
