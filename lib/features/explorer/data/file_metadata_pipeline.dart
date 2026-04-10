import 'dart:convert';
import 'dart:typed_data';

import 'explorer_weekday.dart';

class FileMetadataPipeline {
  static const Set<String> _docExt = {
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'txt',
    'xls',
    'xlsx',
    'md',
    'csv',
    'json',
    'yaml',
    'yml',
    'xml',
  };
  static const Set<String> _mediaExt = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'mp4',
    'mov',
    'avi',
    'mp3',
    'wav',
    'm4a',
  };
  static const Set<String> _codeExt = {
    'dart',
    'js',
    'ts',
    'py',
    'java',
    'cpp',
    'c',
    'h',
    'kt',
    'swift',
    'go',
    'rs',
    'php',
    'html',
    'css',
  };
  static const Set<String> _archiveExt = {
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
  };

  static String? fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return null;
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String blockFor({required String ext, required String mime}) {
    if (_docExt.contains(ext) || mime.startsWith('application/pdf')) return 'Documents Block';
    if (_mediaExt.contains(ext) || mime.startsWith('image/') || mime.startsWith('video/')) return 'Media Block';
    if (_codeExt.contains(ext) || mime.startsWith('text/')) return 'Code Block';
    if (_archiveExt.contains(ext)) return 'Archive Block';
    return 'General Block';
  }

  static String mediaCategoryFor({required String ext, required String mime}) {
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('video/')) return 'video';
    if (mime.startsWith('audio/')) return 'audio';
    if (mime.startsWith('text/')) return 'code';
    if (mime == 'application/pdf' || ext == 'pdf') return 'pdf';
    if (_archiveExt.contains(ext)) return 'archive';
    if (_codeExt.contains(ext)) return 'code';
    if (_docExt.contains(ext)) return 'document';
    return 'other';
  }

  static String organizerDayFor(DateTime whenLocal) => ExplorerWeekday.english(whenLocal);

  // Free, dependency-free checksum (FNV-1a 32-bit) for integrity demos.
  // Uses 32-bit variant to stay JS-safe on Flutter web.
  static String checksumFnv1a64(Uint8List bytes) {
    var hash = 0x811c9dc5;
    const int prime = 0x01000193;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String? maybeExtractTextSnippet({
    required Uint8List bytes,
    required String ext,
    required String mime,
    int maxInputBytes = 256000,
    int maxOutputChars = 500,
  }) {
    final looksText = mime.startsWith('text/') || {'txt', 'md', 'json', 'csv', 'yaml', 'yml', 'xml', 'log', 'ini'}.contains(ext);
    if (!looksText || bytes.isEmpty || bytes.length > maxInputBytes) return null;
    final decoded = utf8.decode(bytes, allowMalformed: true).trim();
    if (decoded.isEmpty) return null;
    if (decoded.length <= maxOutputChars) return decoded;
    return '${decoded.substring(0, maxOutputChars)}...';
  }
}
