import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'weekly_consistency.dart';

String rewardCaption(EarnedReward reward) {
  final text = '${reward.title}\n${reward.detail}';
  return text.runes.length <= 300
      ? text
      : '${String.fromCharCodes(text.runes.take(299))}…';
}

Future<XFile> rewardCover(EarnedReward reward) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 720, 720),
      Paint()..color = const Color(0xff111111));
  const gold = Color(0xffefba58), ink = Color(0xfff5f5f5);
  void text(String value, double y, double size, Color color, {int lines = 1}) {
    final painter = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: size,
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.25)),
        textDirection: TextDirection.ltr,
        maxLines: lines,
        ellipsis: '…')
      ..layout(maxWidth: 624);
    painter.paint(canvas, Offset(48, y));
  }

  text('METE MARCHA · MINHAS CONQUISTAS', 48, 19, gold);
  canvas.drawCircle(
      const Offset(360, 240), 114, Paint()..color = const Color(0xff302617));
  canvas.drawCircle(
      const Offset(360, 240),
      105,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  final number = TextPainter(
      text: TextSpan(
          text: reward.value,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: reward.kind == 'weeks' ? 90 : 48,
              fontWeight: FontWeight.w800,
              color: ink)),
      textDirection: TextDirection.ltr)
    ..layout(maxWidth: 190);
  number.paint(canvas, Offset(360 - number.width / 2, 240 - number.height / 2));
  text(
      reward.kind == 'weeks'
          ? (reward.value == '1'
              ? 'SEMANA ATIVA'
              : 'SEMANAS ATIVAS CONSECUTIVAS')
          : (reward.kind == 'pr'
              ? 'RECORDE PESSOAL'
              : 'CONQUISTA DESBLOQUEADA'),
      380,
      19,
      gold);
  text(reward.title, 420, 36, ink, lines: 2);
  text(reward.detail, 520, 22, const Color(0xffbdbdbd), lines: 5);
  final picture = recorder.endRecording();
  final image = await picture.toImage(720, 720);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return XFile.fromData(data!.buffer.asUint8List(),
      mimeType: 'image/png', name: 'conquista-mete-marcha.png');
}
