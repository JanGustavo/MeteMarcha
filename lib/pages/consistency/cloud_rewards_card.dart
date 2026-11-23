import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/squad_service.dart';
import '../../core/consistency/consistency_provider.dart';

class CloudRewardsCard extends ConsumerStatefulWidget {
  const CloudRewardsCard({super.key, this.api});
  final SquadService? api;
  @override
  ConsumerState<CloudRewardsCard> createState() => _CloudRewardsCardState();
}

class _CloudRewardsCardState extends ConsumerState<CloudRewardsCard> {
  bool visible = false, busy = false;
  String? message;
  SquadService get api => widget.api ?? SquadService();
  Future<void> run(Future<void> Function() work) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await work();
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rewardProvider);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Conquistas na nuvem · opcional',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Envie uma cópia das conquistas e do destaque. Fotos e histórico de treinos não são enviados. É preciso estar conectado à sua conta.'),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: visible,
                      onChanged:
                          busy ? null : (v) => setState(() => visible = v!),
                      title: const Text(
                          'Mostrar meu destaque aos membros dos meus squads'),
                      subtitle: const Text(
                          'Desmarcado: a cópia fica privada. O restante das conquistas não é exposto aos membros.')),
                  FilledButton.tonalIcon(
                      onPressed: busy || !state.ready || state.records.isEmpty
                          ? null
                          : () => run(() async {
                                await api.request('PUT', '/v1/me/rewards', {
                                  'records': [
                                    for (final r in state.records)
                                      {
                                        ...r.toJson(),
                                        'at':
                                            r.earnedAt.toUtc().toIso8601String()
                                      }
                                  ],
                                  'pinned': state.pinned,
                                  'visible_to_squads': visible
                                });
                                if (mounted)
                                  setState(() => message =
                                      'Cópia enviada. Para atualizar depois de novas conquistas, envie novamente.');
                              }),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Enviar cópia para a nuvem')),
                  TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => run(() async {
                                final data =
                                    await api.request('GET', '/v1/me/rewards');
                                final snapshot = data['snapshot'];
                                if (snapshot == null) {
                                  if (mounted)
                                    setState(() => message =
                                        'Nenhuma cópia encontrada nesta conta.');
                                  return;
                                }
                                await ref.read(rewardProvider.notifier).restore(
                                    List<Map<String, dynamic>>.from(
                                        snapshot['records']),
                                    snapshot['pinned']);
                                if (mounted)
                                  setState(() {
                                    visible =
                                        snapshot['visible_to_squads'] == true;
                                    message =
                                        'Conquistas restauradas sem apagar os registros locais.';
                                  });
                              }),
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Restaurar cópia da minha conta')),
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => run(() async {
                                final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Apagar cópia online?'),
                                            content: const Text(
                                                'Remove a cópia e o destaque online. As conquistas locais ficam no aparelho; stories já publicados seguem o prazo normal.'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child:
                                                      const Text('Cancelar')),
                                              FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text(
                                                      'Apagar cópia'))
                                            ]));
                                if (confirmed != true) return;
                                await api.request('DELETE', '/v1/me/rewards');
                                if (mounted)
                                  setState(
                                      () => message = 'Cópia online removida.');
                              }),
                      child: const Text('Apagar minha cópia online')),
                  if (busy) const LinearProgressIndicator(),
                  if (message != null) Text(message!),
                ])));
  }
}

Future<void> showMemberShowcase(
    BuildContext context, SquadService api, String userID, String name) async {
  await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => FutureBuilder<Map<String, dynamic>>(
          future: api.request('GET', '/v1/members/$userID/showcase'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()));
            final pinned = snapshot.data?['pinned'];
            return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      if (pinned == null)
                        const Text(
                            'Este membro não disponibilizou um destaque para o squad.')
                      else ...[
                        Text(pinned['title'],
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(pinned['detail']),
                        const SizedBox(height: 12),
                        const Text('Conquista informada pelo participante.')
                      ],
                    ]));
          }));
}
