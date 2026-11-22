import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

// Bake EXIF before flipping; the saved pixels match the confirmation preview.
Uint8List mirrorPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Imagem inválida');
  final upright = img.bakeOrientation(decoded);
  return Uint8List.fromList(
      img.encodeJpg(img.flipHorizontal(upright), quality: 85));
}

Future<XFile?> pickAppPhoto(
  BuildContext context, {
  required ImageSource source,
  double maxWidth = 1920,
  double? maxHeight,
  CameraDevice camera = CameraDevice.front,
}) async {
  final file = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: 85);
  if (file == null || source != ImageSource.camera || !context.mounted)
    return file;
  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  final mirrored = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => CapturedPhotoReview(
              bytes: bytes, mirrored: camera == CameraDevice.front)));
  if (mirrored == null) return null;
  if (!mirrored) return file;
  final output = await compute(mirrorPhoto, bytes);
  // Keep a real file path for profile and body-measurement storage.
  final result =
      XFile.fromData(output, mimeType: 'image/jpeg', name: 'selfie.jpg');
  if (!kIsWeb) {
    final path = '${file.path}.mirrored.jpg';
    await result.saveTo(path);
    return XFile(path, mimeType: 'image/jpeg');
  }
  return result;
}

class CapturedPhotoReview extends StatefulWidget {
  const CapturedPhotoReview(
      {super.key, required this.bytes, this.mirrored = true});
  final Uint8List bytes;
  final bool mirrored;
  @override
  State<CapturedPhotoReview> createState() => _CapturedPhotoReviewState();
}

class _CapturedPhotoReviewState extends State<CapturedPhotoReview> {
  late bool mirrored = widget.mirrored;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Revisar foto')),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Expanded(
                      child: Center(
                          child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(
                                  mirrored ? -1 : 1, 1, 1),
                              child: Image.memory(widget.bytes,
                                  fit: BoxFit.contain)))),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Espelhar foto'),
                      subtitle:
                          const Text('Confira a posição antes de salvar.'),
                      value: mirrored,
                      onChanged: (value) => setState(() => mirrored = value)),
                  const SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: () => Navigator.pop(context, mirrored),
                          child: const Text('Usar esta foto'))),
                ]))),
      );
}
