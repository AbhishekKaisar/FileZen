import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'explorer_file_bytes_stub.dart' if (dart.library.io) 'explorer_file_bytes_io.dart' as impl;

/// Resolves [PlatformFile] bytes using in-memory data when possible, else native path (non-web).
Future<Uint8List?> resolvePickerFileBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes;
  }
  return impl.readFileAsBytes(file.path);
}
