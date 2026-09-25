import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/web_project_image.dart';

class WebProjectImageRepository {
  WebProjectImageRepository._();

  static const String bucket = 'web-projects';

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<WebProjectImage>> getByProject(
    String projectId,
  ) async {
    final rows = await _db
        .from('web_project_images')
        .select()
        .eq('project_id', projectId)
        .order('sort_order')
        .order('created_at');

    return rows.map((row) => WebProjectImage.fromJson(row)).toList();
  }

  static Future<WebProjectImage> upload({
    required String projectId,
    required Uint8List bytes,
    required String extension,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('La fotografía está vacía.');
    }

    if (bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError(
        'La fotografía supera el límite de 10 MB.',
      );
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

    final path = '$projectId/$filename';

    await _db.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );

    try {
      final row = await _db
          .from('web_project_images')
          .insert({
            'project_id': projectId,
            'storage_path': path,
          })
          .select()
          .single();

      return WebProjectImage.fromJson(row);
    } catch (_) {
      // Si falla el registro en la tabla, intentamos
      // retirar el archivo recién subido.
      try {
        await _db.storage.from(bucket).remove([path]);
      } catch (_) {
        // Una limpieza fallida no debe ocultar el error original.
      }
      rethrow;
    }
  }

  static Future<String> signedUrl(
    String storagePath,
  ) async {
    return _db.storage.from(bucket).createSignedUrl(
          storagePath,
          3600,
        );
  }

  static Future<void> setCover({
    required String projectId,
    required String storagePath,
  }) async {
    final image = await _db
        .from('web_project_images')
        .select('id')
        .eq('project_id', projectId)
        .eq('storage_path', storagePath)
        .maybeSingle();

    if (image == null) {
      throw StateError(
        'La fotografía no pertenece a esta obra.',
      );
    }

    await _db.from('web_projects').update({
      'cover_path': storagePath,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', projectId);
  }

  static Future<void> delete({
    required WebProjectImage image,
    required String? currentCoverPath,
  }) async {
    // Evitamos borrar accidentalmente la portada activa.
    if (currentCoverPath == image.storagePath) {
      throw StateError(
        'Selecciona otra portada antes de eliminar esta fotografía.',
      );
    }

    await _db.storage.from(bucket).remove([
      image.storagePath,
    ]);

    await _db
        .from('web_project_images')
        .delete()
        .eq('id', image.id)
        .eq('project_id', image.projectId);
  }
}
