import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> pickReferenceImage() async {
  final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 768,
      maxHeight: 768,
      imageQuality: 75);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > 256 * 1024)
    throw Exception('Escolha uma imagem menor que 256 KB.');
  return base64Encode(bytes);
}

class ReferenceImage extends StatelessWidget {
  const ReferenceImage({super.key, required this.encoded, this.height = 180});
  final String encoded;
  final double height;
  @override
  Widget build(BuildContext context) {
    try {
      return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(base64Decode(encoded),
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Text('Imagem indisponível')));
    } catch (_) {
      return const Text('Imagem indisponível');
    }
  }
}
