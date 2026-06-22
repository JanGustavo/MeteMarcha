// lib/core/utils/file_saver.dart

import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

void saveFileWeb(String content, String fileName) {
  saveFileWebImpl(content, fileName);
}
