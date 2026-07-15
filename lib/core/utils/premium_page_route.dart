// lib/core/utils/premium_page_route.dart

import 'package:flutter/material.dart';

enum TransitionType {
  slideRight, // Slide from right to left with fade
  slideUp,    // Slide from bottom to top with fade
  fade,       // Clean fade transition
}

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionType transitionType;
  final Duration duration;

  PremiumPageRoute({
    required this.page,
    this.transitionType = TransitionType.slideRight,
    this.duration = const Duration(milliseconds: 250),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case TransitionType.fade:
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              case TransitionType.slideUp:
                // Deslocamento de 8% da altura para uma sensação de profundidade e leveza
                final begin = const Offset(0.0, 0.08);
                const end = Offset.zero;
                final curve = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: begin, end: end).animate(curve),
                    child: child,
                  ),
                );
              case TransitionType.slideRight:
                // Deslocamento de 8% da largura para uma transição fluida horizontal
                final begin = const Offset(0.08, 0.0);
                const end = Offset.zero;
                final curve = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: begin, end: end).animate(curve),
                    child: child,
                  ),
                );
            }
          },
        );
}
