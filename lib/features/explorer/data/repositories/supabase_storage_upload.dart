import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_storage_upload_stub.dart'
    if (dart.library.io) 'supabase_storage_upload_io.dart' as impl;

Future<void> uploadFileToSupabaseStorage({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required Uint8List bytes,
  String? localPath,
  String? contentType,
}) {
  return impl.uploadFileToSupabaseStorage(
    client: client,
    bucket: bucket,
    objectPath: objectPath,
    bytes: bytes,
    localPath: localPath,
    contentType: contentType,
  );
}
