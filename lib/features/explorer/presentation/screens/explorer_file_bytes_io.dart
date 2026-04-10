import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readFileAsBytes(String? path) async {
  if (path == null || path.isEmpty) return null;
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}
