import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/consistency/weekly_consistency.dart';
import '../../../core/consistency/consistency_provider.dart';
import '../../consistency/reward_celebration.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/constants/achievements.dart';
import 'package:gym_tracker/core/widgets/achievement_image.dart';

class ProfileAchievementCard extends StatelessWidget {
  final AchievementStatus status;

  const ProfileAchievementCard({super.key, required this.status});

  Widget _buildEmblem(BuildContext context, {double size = 48}) {
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isLocked = levelIdx == -1;
    final String? levelNameTemp = isLocked ? null : ach.levels[levelIdx].name;

    if (AchievementImage.isSupported(
      ach.id,
      levelNameTemp,
      isLocked: isLocked,
    )) {
      return AchievementImage(
        achievementId: ach.id,
        levelName: levelNameTemp,
        fallbackEmoji: isLocked ? '🔒' : ach.emoji,
        size: size * 1.15,
        isLocked: isLocked,
      );
    }

    Gradient borderGradient;
    Gradient bgGradient;
    String badgeEmoji;
    String? levelName;

    if (isLocked) {
      bgGradient = const LinearGradient(
        colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFF444444), Color(0xFF333333)],
      );
      badgeEmoji = '🔒';
    } else {
      final currentLevel = ach.levels[levelIdx];
      levelName = currentLevel.name;
      badgeEmoji = ach.emoji;
      if (levelName == 'Bronze') {
        bgGradient = const LinearGradient(
          colors: [Color(0xFF8C5230), Color(0xFFE2A785), Color(0xFF8C5230)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderGradient = const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFFFE5D9), Color(0xFFCD7F32)],
        );
      } else if (levelName == 'Prata') {
        bgGradient = const LinearGradient(
          colors: [Color(0xFF6B7B8C), Color(0xFFEBF3FA), Color(0xFF6B7B8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderGradient = const LinearGradient(
          colors: [Color(0xFFB0B8C0), Color(0xFFFFFFFF), Color(0xFFB0B8C0)],
        );
      } else {
        bgGradient = const LinearGradient(
          colors: [Color(0xFFB59410), Color(0xFFFFFAAF), Color(0xFFB59410)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderGradient = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFFFE0), Color(0xFFFFD700)],
        );
      }
    }

    final double width = size;
    final double height = size * 1.15;

    return ClipPath(
      clipper: HexagonClipper(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(gradient: borderGradient),
        padding: const EdgeInsets.all(2.0),
        child: ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            decoration: BoxDecoration(gradient: bgGradient),
            child: Center(
              child: AchievementImage(
                achievementId: ach.id,
                levelName: isLocked ? null : levelName,
                fallbackEmoji: badgeEmoji,
                size: size * 0.7,
                isLocked: isLocked,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isLocked = levelIdx == -1;

    Color barColor = Colors.grey;
    if (!isLocked) {
      final levelName = ach.levels[levelIdx].name;
      if (levelName == 'Bronze') {
        barColor = const Color(0xFFCD7F32);
      } else if (levelName == 'Prata') {
        barColor = const Color(0xFFB0B8C0);
      } else {
        barColor = const Color(0xFFFFD700);
      }
    }

    return InkWell(
      onTap: () => _showAchievementDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmblem(context, size: 52),
            const SizedBox(height: 6),
            Text(
              ach.shortTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isLocked
                    ? context.onSurface.withValues(alpha: 0.5)
                    : context.onBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 3,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLocked ? AppColors.primary : barColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context) {
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isDark = context.isDark;
    final isLocked = levelIdx == -1;
    final String levelName = isLocked ? 'Bloqueado' : ach.levels[levelIdx].name;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showFullscreenBadge(context);
                      },
                      child: Tooltip(
                        message: 'Toque para ampliar',
                        child: Hero(
                          tag: 'ach_badge_${ach.id}_$levelName',
                          child: _buildEmblem(context, size: 56),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ach.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: context.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ach.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.divider.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progresso Atual:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatValue(status.currentValue, ach.type),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status.nextTargetLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(ach.levels.length, (index) {
                    final level = ach.levels[index];
                    final isUnlocked = levelIdx >= index;
                    final isNext = levelIdx + 1 == index;

                    Color color;
                    if (level.name == 'Bronze') {
                      color = const Color(0xFFCD7F32);
                    } else if (level.name == 'Prata') {
                      color = const Color(0xFFB0B8C0);
                    } else {
                      color = const Color(0xFFFFD700);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? color.withValues(alpha: 0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnlocked
                              ? color.withValues(alpha: 0.3)
                              : isNext
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : context.divider.withValues(alpha: 0.15),
                          width: isUnlocked || isNext ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.4,
                            child: AchievementImage(
                              achievementId: ach.id,
                              levelName: level.name,
                              fallbackEmoji: level.icon,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? color
                                        : context.onBackground.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Exige: ${_formatValue(level.value, ach.type)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 18,
                            )
                          else if (isNext)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Próximo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.grey,
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatValue(double val, AchievementType type) {
    if (type == AchievementType.exercise1rm) {
      return '${val.toStringAsFixed(1)} kg';
    } else if (type == AchievementType.totalVolumeTons) {
      return '${val.toStringAsFixed(1)} t';
    } else if (type == AchievementType.totalWorkouts) {
      return '${val.toInt()} ${val.toInt() == 1 ? "treino" : "treinos"}';
    } else if (type == AchievementType.weekStreak) {
      return '${val.toInt()} ${val.toInt() == 1 ? "semana" : "semanas"}';
    } else {
      return '${val.toInt()} ${val.toInt() == 1 ? "série" : "séries"}';
    }
  }

  void _showFullscreenBadge(BuildContext context) {
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isLocked = levelIdx == -1;
    final levelName = isLocked ? 'Bloqueado' : ach.levels[levelIdx].name;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(
        alpha: 0.9,
      ), // Fundo preto opaco elegante
      builder: (ctx) {
        return GestureDetector(
          onTap: () => Navigator.pop(ctx), // Fecha ao tocar fora
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Glow de fundo animado (efeito premium pulsante)
                Center(
                  child: _AchievementGlowBackground(
                    isLocked: isLocked,
                    levelName: levelName,
                  ),
                ),
                // Conteúdo principal
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Título da Conquista
                      Text(
                        ach.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Categoria / Nível
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.white24
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLocked
                                ? Colors.white30
                                : AppColors.primaryLight,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isLocked ? 'Bloqueado' : 'Nível: $levelName',
                          style: TextStyle(
                            color: isLocked
                                ? Colors.white70
                                : AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // O Emblema em tamanho grande e zoomável (InteractiveViewer)
                      SizedBox(
                        width: 280,
                        height: 320,
                        child: InteractiveViewer(
                          clipBehavior: Clip.none,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Hero(
                              tag: 'ach_badge_${ach.id}_$levelName',
                              child: _buildEmblem(context, size: 180),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      // Descrição detalhada
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          ach.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Alvo/Progresso
                      Text(
                        isLocked
                            ? 'Alvo: ${_formatValue(ach.levels[0].value, ach.type)}'
                            : 'Progresso: ${_formatValue(status.currentValue, ach.type)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),

                      // Instrução para sair / fechar
                      const Text(
                        'Toque em qualquer lugar para voltar',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // Botão de compartilhar
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onPressed: isLocked
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final reward = EarnedReward(
                                id: 'achievement:${ach.id}:$levelIdx',
                                title: ach.title,
                                detail: 'Nível $levelName · ${ach.description}',
                                kind: 'achievement',
                                value: levelName,
                                earnedAt: DateTime.now(),
                                seen: true);
                            final controller = ProviderScope.containerOf(
                                    context,
                                    listen: false)
                                .read(rewardProvider.notifier);
                            try {
                              await controller.add(reward);
                              await controller.viewed(reward.id);
                              if (context.mounted)
                                await showRewardCelebration(context, reward);
                            } catch (_) {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Não foi possível abrir o compartilhamento.')));
                            }
                          },
                  ),
                ),
                // Botão de fechar
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementGlowBackground extends StatefulWidget {
  final bool isLocked;
  final String levelName;
  const _AchievementGlowBackground({
    required this.isLocked,
    required this.levelName,
  });

  @override
  State<_AchievementGlowBackground> createState() =>
      _AchievementGlowBackgroundState();
}

class _AchievementGlowBackgroundState extends State<_AchievementGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return const SizedBox.shrink();

    Color glowColor;
    if (widget.levelName == 'Bronze') {
      glowColor = const Color(0xFFCD7F32);
    } else if (widget.levelName == 'Prata') {
      glowColor = const Color(0xFFB0B8C0);
    } else {
      glowColor = const Color(0xFFFFD700);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.15);
        final opacity = 0.15 + (_controller.value * 0.1);

        return Container(
          width: 320 * scale,
          height: 320 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withValues(alpha: opacity),
                glowColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Vertical pointed hexagon (point at top center and bottom center)
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
