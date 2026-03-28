import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveBytesToDevice({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save file',
      fileName: fileName,
      type: FileType.any,
      bytes: bytes,
    );
    if (outputPath == null || outputPath.isEmpty) return false;
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return true;
  } catch (_) {
    return false;
  }
}
