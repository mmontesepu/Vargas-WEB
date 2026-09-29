import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class WebServiceImageRepository {
  WebServiceImageRepository._();

  static const bucket = 'web-services';

  static const serviceKeys = [
    'construction',
    'renovation',
    'finishes',
  ];

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<Map<String, String?>> getAll() async {
    final rows = await _db
        .from('web_service_images')
        .select('service_key, storage_path');

    final result = <String, String?>{
      for (final key in serviceKeys) key: null,
    };

    for (final row in rows) {
      final key = row['service_key'] as String;

      if (result.containsKey(key)) {
        final path = row['storage_path'] as String?;
        result[key] = path == null || path.trim().isEmpty ? null : path;
      }
    }

    return result;
  }

  static Future<String> signedUrl(String path) {
    return _db.storage.from(bucket).createSignedUrl(path, 3600);
  }

  static Future<void> replace({
    required String serviceKey,
    required Uint8List bytes,
    required String extension,
  }) async {
    if (!serviceKeys.contains(serviceKey)) {
      throw ArgumentError('Servicio no válido.');
    }

    if (bytes.isEmpty) {
      throw ArgumentError('La fotografía está vacía.');
    }

    if (bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('La fotografía supera los 10 MB.');
    }

    final ext = extension.toLowerCase().replaceFirst('.', '');

    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError(
          'Formato no permitido. Utiliza JPG, PNG o WebP.',
        ),
    };

    final filename = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final path = '$serviceKey/$filename';

    await _db.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );

    try {
      await _db
          .from('web_service_images')
          .update({
            'storage_path': path,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('service_key', serviceKey)
          .select('service_key')
          .single();
    } catch (_) {
      try {
        await _db.storage.from(bucket).remove([path]);
      } catch (_) {}

      rethrow;
    }
  }

  /// Restaura la imagen referencial del servicio seleccionado.
  /// No elimina físicamente la fotografía anterior del bucket.
  static Future<void> restoreDefault(String serviceKey) async {
    if (!serviceKeys.contains(serviceKey)) {
      throw ArgumentError('Servicio no válido.');
    }

    await _db
        .from('web_service_images')
        .update({
          'storage_path': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('service_key', serviceKey)
        .select('service_key')
        .single();
  }
}
