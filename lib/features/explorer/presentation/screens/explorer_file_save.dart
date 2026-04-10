import 'dart:typed_data';

import 'explorer_file_save_stub.dart' if (dart.library.io) 'explorer_file_save_io.dart' as impl;

Future<bool> saveBytesToDevice({
  required Uint8List bytes,
  required String fileName,
}) {
  return impl.saveBytesToDevice(bytes: bytes, fileName: fileName);
}
