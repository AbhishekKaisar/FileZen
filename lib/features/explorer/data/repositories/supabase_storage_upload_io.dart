import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadFileToSupabaseStorage({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required Uint8List bytes,
  String? localPath,
  String? contentType,
}) async {
  final storage = client.storage.from(bucket);
  final options = FileOptions(
    contentType: contentType ?? 'application/octet-stream',
    upsert: false,
  );

  try {
    if (localPath != null && localPath.isNotEmpty) {
      await storage.upload(
        objectPath,
        File(localPath),
        fileOptions: options,
      );
      return;
    }

    await storage.uploadBinary(
      objectPath,
      bytes,
      fileOptions: options,
    );
    return;
  } on StorageException catch (error) {
    // Work around desktop endpoint issues by posting to the documented REST path.
    final isKnownDesktop404 =
        error.statusCode == '404' && error.message.contains('Invalid Storage request');
    if (!isKnownDesktop404) {
      rethrow;
    }
    await _uploadViaRestEndpoint(
      bucket: bucket,
      objectPath: objectPath,
      bytes: bytes,
      contentType: contentType ?? 'application/octet-stream',
      localPath: localPath,
    );
    return;
  }
}

Future<void> _uploadViaRestEndpoint({
  required String bucket,
  required String objectPath,
  required Uint8List bytes,
  required String contentType,
  String? localPath,
}) async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY are required for storage upload fallback.');
  }

  final uri = Uri.parse(supabaseUrl).replace(
    pathSegments: [
      ...Uri.parse(supabaseUrl).pathSegments.where((segment) => segment.isNotEmpty),
      'storage',
      'v1',
      'object',
      bucket,
      ...objectPath.split('/').where((segment) => segment.isNotEmpty),
    ],
  );

  final boundary = 'filezen-${DateTime.now().microsecondsSinceEpoch}';
  final request = await HttpClient().postUrl(uri);
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $supabaseKey');
  request.headers.set('apikey', supabaseKey);
  request.headers.set('x-upsert', 'false');
  request.headers.contentType = ContentType('multipart', 'form-data', parameters: {
    'boundary': boundary,
  });

  final fileName = objectPath.split('/').last;
  final preamble = StringBuffer()
    ..write('--$boundary\r\n')
    ..write('Content-Disposition: form-data; name="file"; filename="$fileName"\r\n')
    ..write('Content-Type: $contentType\r\n\r\n');
  request.add(utf8.encode(preamble.toString()));

  if (localPath != null && localPath.isNotEmpty) {
    await request.addStream(File(localPath).openRead());
  } else {
    request.add(bytes);
  }

  request.add(utf8.encode('\r\n--$boundary--\r\n'));

  final response = await request.close();
  final responseBody = await utf8.decodeStream(response);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Storage REST upload failed (${response.statusCode}): $responseBody');
  }
}
