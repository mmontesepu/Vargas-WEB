import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class WebSiteSettingsRepository {
  WebSiteSettingsRepository._();

  static const String bucket = 'web-site';
  static const String heroKey = 'hero';

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<String?> getHeroPath() async {
    final row = await _db
        .from('web_site_settings')
        .select('storage_path')
        .eq('setting_key', heroKey)
        .single();

    final path = row['storage_path'] as String?;
    return path == null || path.trim().isEmpty ? null : path;
  }

  static Future<String> signedUrl(String path) {
    return _db.storage.from(bucket).createSignedUrl(path, 3600);
  }

  static Future<void> replaceHero({
    required Uint8List bytes,
    required String extension,
  }) async {
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
    final path = 'hero/$filename';

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
          .from('web_site_settings')
          .update({
            'storage_path': path,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('setting_key', heroKey)
          .select('setting_key')
          .single();
    } catch (_) {
      try {
        await _db.storage.from(bucket).remove([path]);
      } catch (_) {}

      rethrow;
    }
  }

  /// Desactiva la imagen personalizada.
  ///
  /// La página pública volverá a utilizar su imagen referencial.
  /// No borra el archivo físico del bucket.
  static Future<void> restoreDefault() async {
    await _db
        .from('web_site_settings')
        .update({
          'storage_path': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('setting_key', heroKey)
        .select('setting_key')
        .single();
  }
}
