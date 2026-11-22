import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'social_video.dart';

Future<XFile> videoCover(SocialVideo video) async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawRect(const Rect.fromLTWH(0, 0, 720, 720),
      Paint()..color = const Color(0xff111827));
  void text(String value, double y, double size, Color color) {
    final p = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                color: color, fontSize: size, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
        maxLines: 2)
      ..layout(maxWidth: 624);
    p.paint(c, Offset(48, y));
  }

  text('METE MARCHA · REFERÊNCIA', 52, 20, const Color(0xffb8acf9));
  text(video.provider, 120, 42, Colors.white);
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 230, 624, 260), const Radius.circular(24)),
      Paint()..color = const Color(0xff29263f));
  c.drawPath(
      Path()
        ..moveTo(330, 305)
        ..lineTo(330, 415)
        ..lineTo(420, 360)
        ..close(),
      Paint()..color = const Color(0xffb8acf9));
  text('Assista ao vídeo compartilhado', 545, 28, Colors.white);
  text('Toque para abrir o player', 610, 20, const Color(0xffaab0c0));
  final picture = recorder.endRecording();
  final image = await picture.toImage(720, 720);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return XFile.fromData(data!.buffer.asUint8List(),
      name: 'video-reference.png',
      path: 'video-reference.png',
      mimeType: 'image/png');
}
