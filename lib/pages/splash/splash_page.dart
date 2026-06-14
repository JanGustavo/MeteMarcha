// lib/pages/splash/splash_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../core/theme/app_theme.dart';
import '../home/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Dark carbon + crimson glow)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D0D),
                  Color(0xFF1E0D0D), // Subtle dark red glow
                  Color(0xFF090909),
                ],
                stops: [0.1, 0.6, 0.9],
              ),
            ),
          ),

          // Background glowing circle for aesthetic depth
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 120,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),

                  // Glowing Logo Container
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title with Text.rich (METE in bold white, MARCHA in red/italic style)
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 56,
                            height: 0.95,
                            letterSpacing: -2,
                          ),
                      children: [
                        TextSpan(
                          text: 'METE\n',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(
                          text: 'MARCHA',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Treine. Registre. Evolua. ⚡',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Taglines / Motivational Items
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _motivationalItem(
                        Icons.bolt_rounded,
                        'Sem desculpas. Apenas resultados.',
                      ),
                      _motivationalItem(
                        Icons.fitness_center_rounded,
                        'Cargas, séries e intensidade máxima.',
                      ),
                      _motivationalItem(
                        Icons.trending_up_rounded,
                        'Consistência é a chave da evolução.',
                      ),
                    ],
                  ),

                  const Spacer(flex: 4),

                  // METE MARCHA Button (with shake animation)
                  _MeteMarchaShakeWidget(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.vibrate();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'METE MARCHA!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _motivationalItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryLight,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeteMarchaShakeWidget extends StatefulWidget {
  final Widget child;

  const _MeteMarchaShakeWidget({required this.child});

  @override
  State<_MeteMarchaShakeWidget> createState() => _MeteMarchaShakeWidgetState();
}

class _MeteMarchaShakeWidgetState extends State<_MeteMarchaShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasVibrated = false;

  @override
  void initState() {
    super.initState();
    // Shaking dura 600ms e depois há um descanso de 2000ms (total = 2600ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _controller.addListener(() {
      final val = _controller.value;
      if (val < 0.23) {
        if (!_hasVibrated) {
          HapticFeedback.vibrate();
          _hasVibrated = true;
        }
      } else {
        _hasVibrated = false;
      }
    });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getShakeOffsetX(double value) {
    // Shaking acontece nos primeiros 600ms (progresso de 0.0 a 0.23)
    if (value > 0.23) return 0.0;
    final progress = value / 0.23; // Normaliza de 0.0 a 1.0
    return sin(progress * 12 * pi) * 5.0;
  }

  double _getShakeOffsetY(double value) {
    if (value > 0.23) return 0.0;
    final progress = value / 0.23;
    return cos(progress * 14 * pi) * 3.5;
  }

  double _getShakeAngle(double value) {
    if (value > 0.23) return 0.0;
    final progress = value / 0.23;
    return sin(progress * 10 * pi) * 0.025;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final dx = _getShakeOffsetX(val);
        final dy = _getShakeOffsetY(val);
        final angle = _getShakeAngle(val);

        return Transform(
          transform: Matrix4.translationValues(dx, dy, 0.0)..rotateZ(angle),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
