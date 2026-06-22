// lib/core/utils/file_saver_web.dart

import 'dart:convert';
import 'package:web/web.dart' as web;

void saveFileWebImpl(String content, String fileName) {
  final bytes = utf8.encode(content);
  final base64Str = base64Encode(bytes);
  final dataUri = 'data:application/json;base64,$base64Str';

  final anchor = web.HTMLAnchorElement()
    ..href = dataUri
    ..download = fileName;
  anchor.click();
}
