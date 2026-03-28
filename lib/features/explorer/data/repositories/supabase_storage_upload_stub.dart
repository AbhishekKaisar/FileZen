import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadFileToSupabaseStorage({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required Uint8List bytes,
  String? localPath,
  String? contentType,
}) {
  return client.storage.from(bucket).uploadBinary(
        objectPath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType ?? 'application/octet-stream',
          upsert: false,
        ),
      );
}
