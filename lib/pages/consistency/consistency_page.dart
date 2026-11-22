import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/consistency/consistency_provider.dart';
import '../../core/consistency/weekly_consistency.dart';
import 'reward_celebration.dart';

class ConsistencyPage extends ConsumerWidget {
  const ConsistencyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklyConsistencyProvider);
    final rewards = ref.watch(rewardProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Consistência e conquistas')),
        body: summary.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
                child: TextButton(
                    onPressed: () => ref.invalidate(weeklyConsistencyProvider),
                    child: const Text('Tentar carregar histórico novamente'))),
            data: (value) =>
                ListView(padding: const EdgeInsets.all(24), children: [
                  Text('${value.current}',
                      style: Theme.of(context).textTheme.displayLarge),
                  Text(
                      value.current == 1
                          ? 'semana de consistência'
                          : 'semanas de consistência',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(value.activeThisWeek
                      ? 'Sua semana já está ativa. Descansar também faz parte.'
                      : 'A semana está em andamento. Um treino concluído mantém o ritmo.'),
                  const SizedBox(height: 12),
                  const Text(
                      'Cada semana, de segunda a domingo, conta uma vez com pelo menos um treino concluído. Treinar três ou seis vezes vale a mesma semana.'),
                  const SizedBox(height: 24),
                  Wrap(spacing: 24, runSpacing: 12, children: [
                    Text('Melhor sequência: ${value.best} semanas'),
                    Text('${value.activeWeeks.length} semanas ativas no total'),
                    Text('${value.trainingDays} dias com treino')
                  ]),
                  const SizedBox(height: 28),
                  Text('Seus marcos',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'As medalhas conquistadas ficam com você, mesmo depois de uma pausa.'),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                      builder: (_, constraints) => GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount:
                                  constraints.maxWidth >= 700 ? 4 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: .9,
                              children: [
                                for (final weeks in consistencyMilestones)
                                  Builder(builder: (context) {
                                    final id = 'weeks:$weeks';
                                    final earned = value.best >= weeks ||
                                        rewards.records.any((r) => r.id == id);
                                    return Card(
                                        child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: !earned
                                                ? null
                                                : () async {
                                                    try {
                                                      await ref
                                                          .read(rewardProvider
                                                              .notifier)
                                                          .sync(value);
                                                      final reward = ref
                                                          .read(rewardProvider)
                                                          .records
                                                          .firstWhere((r) =>
                                                              r.id == id);
                                                      await ref
                                                          .read(rewardProvider
                                                              .notifier)
                                                          .viewed(id);
                                                      if (context.mounted)
                                                        await showRewardCelebration(
                                                            context, reward);
                                                    } catch (_) {
                                                      if (context.mounted)
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        'Não foi possível abrir a conquista. Tente novamente.')));
                                                    }
                                                  },
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Flexible(
                                                          child:
                                                              ConsistencyMedal(
                                                                  value:
                                                                      '$weeks',
                                                                  size: 92,
                                                                  locked:
                                                                      !earned)),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          '$weeks ${weeks == 1 ? 'semana' : 'semanas'}',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text(earned
                                                          ? 'Conquistado'
                                                          : 'Em construção'),
                                                    ]))));
                                  }),
                              ])),
                  const SizedBox(height: 28),
                  Text('Suas conquistas',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (!rewards.ready && rewards.error == null)
                    const LinearProgressIndicator(),
                  if (rewards.error != null)
                    TextButton(
                        onPressed: () =>
                            ref.read(rewardProvider.notifier).load(),
                        child: Text(rewards.error!)),
                  if (rewards.ready && rewards.records.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                            'O primeiro treino concluído abre a sua primeira semana. Seus recordes e medalhas aparecerão aqui.')),
                  for (final reward in rewards.records)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(reward.kind == 'weeks'
                            ? Icons.workspace_premium_outlined
                            : Icons.emoji_events_outlined),
                        title: Text(reward.title),
                        subtitle: Text(
                            reward.kind == 'weeks'
                                ? (reward.value == '1'
                                    ? '1 semana ativa'
                                    : '${reward.value} semanas consecutivas')
                                : reward.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        trailing: reward.seen
                            ? const Icon(Icons.chevron_right)
                            : const Badge(child: Icon(Icons.chevron_right)),
                        onTap: () async {
                          await ref
                              .read(rewardProvider.notifier)
                              .viewed(reward.id);
                          if (context.mounted)
                            await showRewardCelebration(context, reward);
                        }),
                ])));
  }
}

class RewardInboxButton extends ConsumerWidget {
  const RewardInboxButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(rewardProvider).unread.length;
    return IconButton(
        tooltip:
            unread > 0 ? '$unread conquistas para ver' : 'Minhas conquistas',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ConsistencyPage())),
        icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_none)));
  }
}

class ConsistencyProfileShowcase extends ConsumerWidget {
  const ConsistencyProfileShowcase({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(rewardProvider).showcase;
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: reward == null
              ? const Icon(Icons.workspace_premium_outlined)
              : ConsistencyMedal(value: reward.value, size: 64),
          title:
              Text(reward == null ? 'Sua vitrine de conquistas' : reward.title),
          subtitle: Text(
              reward == null
                  ? 'Escolha uma medalha ou recorde para destacar no perfil.'
                  : reward.kind == 'weeks'
                      ? (reward.value == '1'
                          ? '1 semana ativa'
                          : '${reward.value} semanas ativas consecutivas')
                      : reward.detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ConsistencyPage())),
        ));
  }
}

/// One host presents queued rewards only when the home route is visible.
class ConsistencyHost extends ConsumerStatefulWidget {
  const ConsistencyHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ConsistencyHost> createState() => _ConsistencyHostState();
}

class _ConsistencyHostState extends ConsumerState<ConsistencyHost>
    with WidgetsBindingObserver {
  bool syncing = false, celebrating = false;
  String lastSynced = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(consistencyClockProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(weeklyConsistencyProvider).valueOrNull;
    final rewards = ref.watch(rewardProvider);
    final syncKey = summary == null
        ? ''
        : '${summary.best}:${summary.activeWeeks.length}:${weekDateKey(summary.monday)}';
    if (summary != null && rewards.ready && !syncing && lastSynced != syncKey) {
      syncing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (mounted) {
            await ref.read(rewardProvider.notifier).sync(summary);
            lastSynced = syncKey;
            if (mounted) setState(() {});
          }
        } catch (_) {
          /* Leave the record pending for a later retry. */
        } finally {
          syncing = false;
        }
      });
    }
    if (rewards.unread.isNotEmpty &&
        ModalRoute.of(context)?.isCurrent == true &&
        !celebrating) {
      celebrating = true;
      final reward = rewards.unread.first;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
          await ref.read(rewardProvider.notifier).viewed(reward.id);
          if (mounted) await showRewardCelebration(context, reward);
        } catch (_) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Sua conquista está na lista para você abrir depois.')));
        } finally {
          celebrating = false;
          if (mounted) setState(() {});
        }
      });
    }
    return widget.child;
  }
}
