import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import 'weekly_consistency.dart';

// Refresh a week boundary while the app remains open, as well as on resume.
final consistencyClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
final weeklyConsistencyProvider =
    Provider<AsyncValue<WeeklyConsistency>>((ref) {
  final now = ref.watch(consistencyClockProvider).valueOrNull ?? DateTime.now();
  return ref.watch(completedSessionsProvider).whenData((sessions) =>
      WeeklyConsistency.calculate(
          sessions.map((s) => DateTime.tryParse(s.data)).whereType<DateTime>(),
          now));
});

class RewardState {
  const RewardState(
      {this.records = const [], this.pinned, this.ready = false, this.error});
  final List<EarnedReward> records;
  final String? pinned, error;
  final bool ready;
  List<EarnedReward> get unread => records.where((r) => !r.seen).toList();
  EarnedReward? get showcase {
    for (final r in records) {
      if (r.id == pinned) return r;
    }
    return null;
  }
}

final rewardProvider = StateNotifierProvider<RewardController, RewardState>(
    (ref) => RewardController());

class RewardController extends StateNotifier<RewardState> {
  RewardController() : super(const RewardState()) {
    load();
  }
  static const key = 'mm.earned_rewards.v1';
  Future<void> _pending = Future.value();
  Future<void> _run(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      final data = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final records = [
        for (final item in data['records'] ?? [])
          EarnedReward.fromJson(Map<String, dynamic>.from(item))
      ];
      if (mounted)
        state =
            RewardState(records: records, pinned: data['pinned'], ready: true);
    } catch (_) {
      if (mounted)
        state = const RewardState(
            error: 'Não foi possível carregar suas conquistas.');
    }
  }

  Future<void> _save(List<EarnedReward> records, {String? pinned}) async {
    final next = RewardState(
        records: records, pinned: pinned ?? state.pinned, ready: true);
    // Persist before publishing, so failed writes cannot appear as earned/saved.
    final saved = await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode({
          'records': [for (final r in records) r.toJson()],
          'pinned': next.pinned
        }));
    if (!saved) throw StateError('Não foi possível salvar a conquista.');
    if (mounted) state = next;
  }

  Future<void> sync(WeeklyConsistency summary) => _run(() async {
        if (!state.ready) return;
        final fresh = <EarnedReward>[];
        for (final weeks in consistencyMilestones) {
          final id = 'weeks:$weeks';
          if (summary.best >= weeks && !state.records.any((r) => r.id == id)) {
            fresh.add(EarnedReward(
                id: id,
                title: weeks == 1 ? 'Primeira semana ativa' : 'Ritmo constante',
                detail:
                    '$weeks ${weeks == 1 ? 'semana ativa' : 'semanas ativas consecutivas'}. Uma semana conta com pelo menos um treino concluído.',
                kind: 'weeks',
                value: '$weeks',
                earnedAt: DateTime.now()));
          }
        }
        if (fresh.isEmpty) return;
        // A historical import can cross several milestones; celebrate its highest once.
        final additions = [
          for (var i = 0; i < fresh.length; i++)
            i < fresh.length - 1 ? fresh[i].viewed() : fresh[i]
        ];
        await _save([...additions.reversed, ...state.records]);
      });
  Future<void> add(EarnedReward reward) => _run(() async {
        if (!state.ready) await load();
        if (!state.ready) throw StateError('Conquistas indisponíveis');
        if (state.records.any((r) => r.id == reward.id)) return;
        await _save([reward, ...state.records]);
      });
  Future<void> viewed(String id) => _run(() =>
      _save([for (final r in state.records) r.id == id ? r.viewed() : r]));
  Future<void> pin(String id) => _run(() async {
        if (!state.records.any((r) => r.id == id)) return;
        await _save(state.records, pinned: id);
      });
  Future<void> restore(List<Map<String, dynamic>> records, String? pinned) =>
      _run(() async {
        if (!state.ready) await load();
        if (!state.ready) throw StateError('Conquistas indisponíveis');
        final merged = [...state.records];
        for (final raw in records) {
          final record = EarnedReward.fromJson(raw);
          if (!merged.any((r) => r.id == record.id))
            merged.add(record.viewed());
        }
        await _save(merged,
            pinned: pinned != null && merged.any((r) => r.id == pinned)
                ? pinned
                : state.pinned);
      });
}
