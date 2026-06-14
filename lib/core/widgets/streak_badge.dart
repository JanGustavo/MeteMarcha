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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      );
    } else {
      // Estilo maior para o card do Perfil
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OFENSIVA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(
                Icons.local_fire_department_rounded,
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$streak ${streak == 1 ? "semana" : "semanas"}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.onBackground,
            ),
          ),
        ],
      );
    }
  }
}
