// lib/core/widgets/streak_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/progress_extended_provider.dart';
import '../theme/app_theme.dart';

enum StreakStyle { appBar, profile }

class StreakBadge extends ConsumerStatefulWidget {
  final StreakStyle style;
  const StreakBadge({super.key, required this.style});

  @override
  ConsumerState<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends ConsumerState<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    // Animação de bounce (escala) para quando o streak aumenta
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.95).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_controller);

    // Animação de tremor (shake) para quando o streak reseta para zero
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);

    // Monitora alterações do streakProvider para disparar as micro-animações
    ref.listen<int>(streakProvider, (previous, next) {
      if (previous == null) return;
      if (next > previous) {
        setState(() => _isResetting = false);
        _controller.forward(from: 0.0);
      } else if (next == 0 && previous > 0) {
        setState(() => _isResetting = true);
        _controller.forward(from: 0.0);
      }
    });

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double dx = _isResetting ? _shakeAnimation.value : 0.0;
        final double scale = _isResetting ? 1.0 : _scaleAnimation.value;

        return Transform.translate(
          offset: Offset(dx, 0.0),
          child: Transform.scale(
            scale: scale,
            child: _buildBadge(streak),
          ),
        );
      },
    );
  }

  Widget _buildBadge(int streak) {
    final hasStreak = streak > 0;
    final color = hasStreak ? Colors.orangeAccent : Colors.grey;

    if (widget.style == StreakStyle.appBar) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: hasStreak ? Colors.orange.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasStreak ? Colors.orange.withOpacity(0.25) : Colors.grey.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      // Estilo maior e premium para o card do Perfil
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasStreak ? Colors.orange.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: hasStreak ? Colors.orange.withOpacity(0.25) : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OFENSIVA ATUAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: context.onSurface.withOpacity(0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak ${streak == 1 ? "semana" : "semanas"}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.onBackground,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
