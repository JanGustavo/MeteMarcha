import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_video.dart';
import 'embedded_video_native.dart'
    if (dart.library.js_interop) 'embedded_video_web.dart';

class SocialVideoCard extends StatefulWidget {
  const SocialVideoCard(
      {super.key, required this.url, this.beforePlay, this.active = true});
  final String url;
  final Future<void> Function()? beforePlay;
  final bool active;
  @override
  State<SocialVideoCard> createState() => _SocialVideoCardState();
}

class _SocialVideoCardState extends State<SocialVideoCard> {
  bool opened = false;
  @override
  void didUpdateWidget(covariant SocialVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || (oldWidget.active && !widget.active))
      opened = false;
  }

  @override
  Widget build(BuildContext context) {
    final video = SocialVideo.parse(widget.url);
    if (video == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (opened)
        AspectRatio(
            aspectRatio: video.provider == 'YouTube' ? 16 / 9 : 9 / 16,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: EmbeddedVideo(video: video)))
      else
        Semantics(
          button: true,
          label: 'Assistir vídeo do ${video.provider}',
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await widget.beforePlay?.call();
              if (mounted) setState(() => opened = true);
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(fit: StackFit.expand, children: [
                  ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                  if (video.provider == 'YouTube')
                    Image.network(
                        'https://i.ytimg.com/vi/${video.player.pathSegments.last}/hqdefault.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  const ColoredBox(color: Color(0x33000000)),
                  const Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 64, color: Colors.white)),
                  Positioned(
                      left: 16,
                      bottom: 12,
                      child: Text(video.provider,
                          style: const TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.black54)))
                ]),
              ),
            ),
          ),
        ),
      TextButton.icon(
          onPressed: () =>
              launchUrl(video.original, mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Abrir link original')),
    ]);
  }
}
