import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../consistency/consistency_provider.dart';
import '../../pages/consistency/consistency_page.dart';

enum StreakStyle { appBar, profile }

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key, required this.style});
  final StreakStyle style;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklyConsistencyProvider);
    return summary.when(
        loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => IconButton(
            tooltip: 'Recarregar consistência',
            onPressed: () => ref.invalidate(weeklyConsistencyProvider),
            icon: const Icon(Icons.refresh)),
        data: (value) => Semantics(
            label:
                '${value.current} semanas de consistência. Abrir conquistas.',
            button: true,
            child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ConsistencyPage())),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(value.current),
                  tween: Tween(begin: .85, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.local_fire_department_outlined,
                            color: Color(0xffefba58), size: 24),
                        const SizedBox(width: 6),
                        if (style == StreakStyle.appBar)
                          Text('${value.current} sem',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800))
                        else
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                const Text('CONSISTÊNCIA',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    value.current == 0
                                        ? 'Começando'
                                        : '${value.current} ${value.current == 1 ? 'semana' : 'semanas'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                              ])),
                      ])),
                ))));
  }
}
