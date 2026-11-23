import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/consistency/weekly_consistency.dart';
import '../../core/consistency/consistency_provider.dart';
import '../../core/consistency/reward_sharing.dart';
import '../../core/services/squad_service.dart';
import '../squads/squads_page.dart';

class ConsistencyMedal extends StatelessWidget {
  const ConsistencyMedal(
      {super.key, required this.value, this.size = 100, this.locked = false});
  final String value;
  final double size;
  final bool locked;
  @override
  Widget build(BuildContext context) => Semantics(
      label: locked ? 'Marco ainda não alcançado' : 'Medalha: $value',
      child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
              painter:
                  _MedalPainter(locked ? Colors.grey : const Color(0xffefba58)),
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(size * .2),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(value,
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: size * .29,
                                  fontWeight: FontWeight.w900,
                                  color: locked
                                      ? Colors.grey
                                      : const Color(0xffefba58)))))))));
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * .34;
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: .09));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var side in [-1, 1]) {
      for (var i = 0; i < 6; i++) {
        final angle = (25 + i * 26) * math.pi / 180;
        final pos = c +
            Offset(
                side * math.sin(angle) * r * 1.23, math.cos(angle) * r * 1.23);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(side * angle);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero,
                width: size.width * .055,
                height: size.width * .13),
            Paint()..color = color.withValues(alpha: .8));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.color != color;
}

Future<void> showRewardCelebration(
    BuildContext context, EarnedReward reward) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => RewardCelebration(reward: reward));
}

class RewardCelebration extends ConsumerStatefulWidget {
  const RewardCelebration({super.key, required this.reward});
  final EarnedReward reward;
  @override
  ConsumerState<RewardCelebration> createState() => _RewardCelebrationState();
}

class _RewardCelebrationState extends ConsumerState<RewardCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850));
  bool busy = false;
  String? error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.value = 1;
    } else if (!animation.isAnimating && animation.value == 0) {
      animation.forward();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  Future<void> action(Future<void> Function() run) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await run();
    } catch (_) {
      if (mounted)
        setState(() => error = 'Não foi possível concluir. Tente novamente.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final pinned = ref.watch(rewardProvider).pinned == reward.id;
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                      tooltip: 'Fechar celebração',
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close))),
              AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) => CustomPaint(
                      painter: _CelebrationParticles(
                          MediaQuery.disableAnimationsOf(context)
                              ? 1
                              : animation.value),
                      child: Transform.scale(
                          scale: .8 +
                              .2 *
                                  Curves.easeOutCubic
                                      .transform(animation.value),
                          child: child)),
                  child: ConsistencyMedal(value: reward.value, size: 158)),
              const SizedBox(height: 12),
              Text('Essa conquista é sua.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(reward.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(reward.detail, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => action(() async {
                                final image = await rewardCover(reward);
                                if (!mounted) return;
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => StoryComposer(
                                            api: SquadService(),
                                            initialPhoto: image,
                                            initialCaption:
                                                rewardCaption(reward))));
                              }),
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('Compartilhar no squad'))),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => action(() async {
                                await ref
                                    .read(rewardProvider.notifier)
                                    .pin(reward.id);
                              }),
                      icon: Icon(
                          pinned ? Icons.push_pin : Icons.push_pin_outlined),
                      label: Text(pinned
                          ? 'Em destaque no perfil'
                          : 'Destacar no perfil'))),
              TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => action(() async {
                            final image = await rewardCover(reward);
                            if (!mounted) return;
                            final box =
                                context.findRenderObject() as RenderBox?;
                            await SharePlus.instance.share(ShareParams(
                                files: [
                                  image
                                ],
                                fileNameOverrides: const [
                                  'conquista-mete-marcha.png'
                                ],
                                text: '${reward.title}\n${reward.detail}',
                                sharePositionOrigin: box == null
                                    ? null
                                    : box.localToGlobal(Offset.zero) &
                                        box.size));
                          }),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Compartilhar em outro app')),
              if (error != null)
                Text(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (busy) const LinearProgressIndicator(),
              TextButton(
                  onPressed: busy ? null : () => Navigator.pop(context),
                  child: const Text('Continuar')),
            ])));
  }
}

class _CelebrationParticles extends CustomPainter {
  _CelebrationParticles(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 1) return;
    for (var i = 0; i < 20; i++) {
      final angle = i * 2.39996;
      final radius = (20 + size.width * .55 * progress);
      final at = Offset(size.width / 2 + math.cos(angle) * radius,
          size.height / 2 + math.sin(angle) * radius - 50 * progress);
      canvas.drawCircle(
          at,
          2 + (i % 3).toDouble(),
          Paint()
            ..color =
                (i.isEven ? const Color(0xffefba58) : const Color(0xffef5350))
                    .withValues(alpha: 1 - progress));
    }
  }

  @override
  bool shouldRepaint(_CelebrationParticles old) => old.progress != progress;
}
