import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final trainingFocusProvider =
    StateNotifierProvider<TrainingFocusController, AsyncValue<String?>>(
        (ref) => TrainingFocusController());

class TrainingFocusController extends StateNotifier<AsyncValue<String?>> {
  TrainingFocusController() : super(const AsyncLoading()) {
    load();
  }
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('mm.training.focus');
      if (mounted) state = AsyncData(value);
    } catch (e, s) {
      if (mounted) state = AsyncError(e, s);
    }
  }

  Future<void> select(String focus) async {
    if (!['musculacao', 'calistenia'].contains(focus))
      throw ArgumentError('Foco inválido');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mm.training.focus', focus);
    if (mounted) state = AsyncData(focus);
  }
}
