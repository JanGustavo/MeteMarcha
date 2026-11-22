import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_video.dart';
import 'social_video_card.dart';

Future<void> openReferenceVideo(BuildContext context, String url,
    {String? title}) async {
  if (SocialVideo.parse(url) == null) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'https')
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => Scaffold(
              appBar: AppBar(title: Text(title ?? 'Vídeo de execução')),
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SocialVideoCard(url: url)))));
}
