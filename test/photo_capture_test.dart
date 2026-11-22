import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:gym_tracker/core/media/photo_capture.dart';

void main() {
  final image = img.Image(width: 40, height: 20)
    ..clear(img.ColorRgb8(255, 0, 0));
  img.fillRect(image,
      x1: 20, y1: 0, x2: 39, y2: 19, color: img.ColorRgb8(0, 0, 255));
  final bytes = Uint8List.fromList(img.encodeJpg(image));
  test('espelhamento altera os pixels salvos', () {
    final result = img.decodeImage(mirrorPhoto(bytes))!;
    expect(result.width, 40);
    expect(result.height, 20);
    expect(result.getPixel(3, 10).b, greaterThan(200));
    expect(result.getPixel(36, 10).r, greaterThan(200));
  });
  testWidgets('prévia deixa escolher o espelhamento antes de salvar',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CapturedPhotoReview(bytes: bytes)));
                },
                child: const Text('Abrir')))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);
    await tester.tap(find.text('Espelhar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar esta foto'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
