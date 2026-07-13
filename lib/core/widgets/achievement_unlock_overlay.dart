// lib/core/widgets/achievement_unlock_overlay.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/progress_extended_provider.dart';
import 'achievement_image.dart';

class AchievementUnlockOverlay extends StatefulWidget {
  final AchievementStatus status;
  final VoidCallback onDismiss;

  const AchievementUnlockOverlay({
    super.key,
    required this.status,
    required this.onDismiss,
  });

  static void show(BuildContext context, AchievementStatus status) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => AchievementUnlockOverlay(
        status: status,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<AchievementUnlockOverlay> createState() => _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss após 4.5 segundos
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ach = widget.status.achievement;
    final levelIdx = widget.status.unlockedLevelIndex;
    final levelName = levelIdx >= 0 ? ach.levels[levelIdx].name : 'Bronze';
    final levelIcon = levelIdx >= 0 ? ach.levels[levelIdx].icon : '🥉';

    Gradient borderGradient;
    Gradient bgGradient;
    Color levelColor;

    if (levelName == 'Bronze') {
      levelColor = const Color(0xFFCD7F32);
      bgGradient = const LinearGradient(
        colors: [Color(0xFF8C5230), Color(0xFFE2A785), Color(0xFF8C5230)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFFCD7F32), Color(0xFFFFE5D9), Color(0xFFCD7F32)],
      );
    } else if (levelName == 'Prata') {
      levelColor = const Color(0xFFB0B8C0);
      bgGradient = const LinearGradient(
        colors: [Color(0xFF6B7B8C), Color(0xFFEBF3FA), Color(0xFF6B7B8C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFFB0B8C0), Color(0xFFFFFFFF), Color(0xFFB0B8C0)],
      );
    } else {
      levelColor = const Color(0xFFFFD700);
      bgGradient = const LinearGradient(
        colors: [Color(0xFFB59410), Color(0xFFFFFAAF), Color(0xFFB59410)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFFFE0), Color(0xFFFFD700)],
      );
    }

    return Positioned(
      bottom: 60,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: levelColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Hexágono do Emblema
                        AchievementImage.isSupported(ach.id, levelName)
                            ? AchievementImage(
                                achievementId: ach.id,
                                levelName: levelName,
                                fallbackEmoji: ach.emoji,
                                size: 60,
                              )
                            : ClipPath(
                                clipper: HexagonClipperOverlay(),
                                child: Container(
                                  width: 52,
                                  height: 60,
                                  decoration: BoxDecoration(gradient: borderGradient),
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipPath(
                                    clipper: HexagonClipperOverlay(),
                                    child: Container(
                                      decoration: BoxDecoration(gradient: bgGradient),
                                      child: Center(
                                        child: AchievementImage(
                                          achievementId: ach.id,
                                          levelName: levelName,
                                          fallbackEmoji: ach.emoji,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(width: 16),
                        // Informações da Conquista
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CONQUISTA DESBLOQUEADA! 🎉',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: levelColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ach.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nível $levelName $levelIcon',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonClipperOverlay extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
