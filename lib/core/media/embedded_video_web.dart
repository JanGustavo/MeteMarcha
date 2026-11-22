import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'social_video.dart';

class EmbeddedVideo extends StatelessWidget {
  const EmbeddedVideo({super.key, required this.video});
  final SocialVideo video;
  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (element) {
        final frame = element as web.HTMLIFrameElement;
        frame.src = video.player.toString();
        frame.title = 'Vídeo de referência';
        frame.allow =
            'autoplay; encrypted-media; fullscreen; picture-in-picture';
        frame.referrerPolicy = 'strict-origin-when-cross-origin';
        frame.style.width = '100%';
        frame.style.height = '100%';
        frame.style.border = '0';
      });
}
