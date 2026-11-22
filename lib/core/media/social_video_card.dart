import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_video.dart';
import 'embedded_video_native.dart'
    if (dart.library.js_interop) 'embedded_video_web.dart';

class SocialVideoCard extends StatefulWidget {
  const SocialVideoCard({super.key, required this.url, this.beforePlay});
  final String url;
  final Future<void> Function()? beforePlay;
  @override
  State<SocialVideoCard> createState() => _SocialVideoCardState();
}

class _SocialVideoCardState extends State<SocialVideoCard> {
  bool opened = false;
  @override
  void didUpdateWidget(covariant SocialVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) opened = false;
  }

  @override
  Widget build(BuildContext context) {
    final video = SocialVideo.parse(widget.url);
    if (video == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (opened)
        SizedBox(
            height: video.provider == 'YouTube' ? 240 : 480,
            child: EmbeddedVideo(video: video))
      else
        OutlinedButton.icon(
            onPressed: () async {
              await widget.beforePlay?.call();
              if (mounted) setState(() => opened = true);
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text('Assistir aqui · ${video.provider}')),
      TextButton.icon(
          onPressed: () =>
              launchUrl(video.original, mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Abrir link original')),
    ]);
  }
}
