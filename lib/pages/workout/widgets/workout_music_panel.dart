import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/progress_extended_provider.dart';

class WorkoutMusicPanel extends ConsumerStatefulWidget {
  const WorkoutMusicPanel({super.key});

  @override
  ConsumerState<WorkoutMusicPanel> createState() => _WorkoutMusicPanelState();
}

class _WorkoutMusicPanelState extends ConsumerState<WorkoutMusicPanel> {
  String? _customAppName;
  String? _customAppPackage;

  @override
  void initState() {
    super.initState();
    _loadCustomApp();
  }

  Future<void> _loadCustomApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customAppName = prefs.getString('custom_music_app_name');
      _customAppPackage = prefs.getString('custom_music_app_package');
    });
  }

  Future<void> _clearCustomApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_music_app_name');
    await prefs.remove('custom_music_app_package');
    setState(() {
      _customAppName = null;
      _customAppPackage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(workoutMusicProvider);
    final musicNotifier = ref.read(workoutMusicProvider.notifier);

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.music_note_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text(
                      'Rádio de Treino',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.divider),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: AppColors.primary.withOpacity(0.1),
                      child: musicState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                              ),
                            )
                          : Icon(
                              musicState.isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
                              color: AppColors.primaryLight,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musicChannels[musicState.currentChannelIndex].name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.onBackground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          musicChannels[musicState.currentChannelIndex].genre,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      musicState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: context.onBackground,
                      size: 28,
                    ),
                    onPressed: () => musicNotifier.togglePlay(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.stop_rounded,
                      color: context.onSurface,
                      size: 24,
                    ),
                    onPressed: () => musicNotifier.stop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estações de Foco / Energia',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(musicChannels.length, (index) {
                final channel = musicChannels[index];
                final isSelected = musicState.currentChannelIndex == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == musicChannels.length - 1 ? 0 : 4,
                    ),
                    child: InkWell(
                      onTap: () => musicNotifier.playChannel(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : context.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : context.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              channel.name.split(' ').first,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primaryLight : context.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              channel.genre.split(' / ').first,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              'Abrir em aplicativos externos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const MusicAppLinkButton(
                    name: 'Spotify',
                    assetPath: 'assets/images/spotify.png',
                    packageName: 'com.spotify.music',
                    url: 'spotify:',
                    fallbackUrl: 'https://open.spotify.com',
                  ),
                  const SizedBox(width: 8),
                  const MusicAppLinkButton(
                    name: 'YT Music',
                    assetPath: 'assets/images/ytmusic.png',
                    packageName: 'com.google.android.apps.youtube.music',
                    url: 'https://music.youtube.com',
                    fallbackUrl: 'https://music.youtube.com',
                  ),
                  const SizedBox(width: 8),
                  const MusicAppLinkButton(
                    name: 'Deezer',
                    assetPath: 'assets/images/deezer.png',
                    packageName: 'deezer.android.app',
                    url: 'deezer://',
                    fallbackUrl: 'https://www.deezer.com',
                  ),
                  const SizedBox(width: 8),
                  const MusicAppLinkButton(
                    name: 'Samsung',
                    assetPath: 'assets/images/samsung_music.png',
                    packageName: 'com.sec.android.app.music',
                    url: 'android-music-player://',
                    fallbackUrl: 'https://play.google.com/store/apps/details?id=com.sec.android.app.music',
                  ),
                  const SizedBox(width: 8),
                  const MusicAppLinkButton(
                    name: 'Mi Music',
                    assetPath: 'assets/images/mi_music.png',
                    packageName: 'com.miui.player',
                    url: 'miui-music://',
                    fallbackUrl: 'https://play.google.com/store/apps/details?id=com.miui.player',
                  ),
                  if (_customAppName != null && _customAppPackage != null) ...[
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        MusicAppLinkButton(
                          name: _customAppName!,
                          assetPath: 'assets/images/generic_player.png',
                          packageName: _customAppPackage,
                          url: 'intent:#Intent;package=$_customAppPackage;end',
                          fallbackUrl: 'https://play.google.com/store/apps/details?id=$_customAppPackage',
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _clearCustomApp,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicAppLinkButton extends StatelessWidget {
  final String name;
  final String assetPath;
  final String? packageName;
  final String url;
  final String fallbackUrl;

  const MusicAppLinkButton({
    super.key,
    required this.name,
    required this.assetPath,
    this.packageName,
    required this.url,
    required this.fallbackUrl,
  });

  static const _channel = MethodChannel('dev.jangustavo.metemarcha/app_launcher');

  Future<void> _launch() async {
    if (packageName != null) {
      try {
        final bool launched = await _channel.invokeMethod('launchApp', {
          'packageName': packageName,
        });
        if (launched) return;
      } catch (_) {}
    }

    try {
      final appUri = Uri.parse(url);
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (launched) return;
    } catch (_) {}

    try {
      final webUri = Uri.parse(fallbackUrl);
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launch,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.divider),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                assetPath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
