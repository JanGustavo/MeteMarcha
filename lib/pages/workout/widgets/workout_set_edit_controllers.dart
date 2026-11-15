import 'package:flutter/material.dart';
import 'package:gym_tracker/pages/workout/models/workout_set_entry.dart';

class WorkoutSetEditControllers {
  final WorkoutSetEntry entry;
  final TextEditingController pesoCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController obsCtrl;
  String? equipamento;

  WorkoutSetEditControllers({
    required this.entry,
    required this.pesoCtrl,
    required this.repsCtrl,
    required this.obsCtrl,
    this.equipamento,
  });

  void dispose() {
    pesoCtrl.dispose();
    repsCtrl.dispose();
    obsCtrl.dispose();
  }
}
