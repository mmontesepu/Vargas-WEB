import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/web_project.dart';

class WebProjectRepository {
  WebProjectRepository._();

  static SupabaseClient get _db => Supabase.instance.client;

  // Administración: incluye publicados y borradores.

  static Future<List<WebProject>> getAll() async {
    final rows = await _db
        .from('web_projects')
        .select()
        .order('featured', ascending: false)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return rows.map((row) => WebProject.fromJson(row)).toList();
  }

  // Página pública: solamente obras publicadas con portada.

  static Future<List<WebProject>> getPublished() async {
    final rows = await _db
        .from('web_projects')
        .select()
        .eq('published', true)
        .not('cover_path', 'is', null)
        .order('featured', ascending: false)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return rows
        .map((row) => WebProject.fromJson(row))
        .where(
          (project) => project.coverPath?.trim().isNotEmpty ?? false,
        )
        .toList();
  }

  static Future<WebProject> create({
    required String title,
    required String category,
    required String location,
    required String description,
    bool featured = false,
    int sortOrder = 0,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('El título es obligatorio.');
    }

    if (sortOrder < 0) {
      throw ArgumentError('El orden no puede ser negativo.');
    }

    final row = await _db
        .from('web_projects')
        .insert({
          'title': cleanTitle,
          'category': category,
          'location': location.trim(),
          'description': description.trim(),
          'featured': featured,
          'sort_order': sortOrder,
          'published': false,
        })
        .select()
        .single();

    return WebProject.fromJson(row);
  }

  static Future<void> update({
    required String id,
    required String title,
    required String category,
    required String location,
    required String description,
    required bool featured,
    required int sortOrder,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('El título es obligatorio.');
    }

    if (sortOrder < 0) {
      throw ArgumentError('El orden no puede ser negativo.');
    }

    await _db.from('web_projects').update({
      'title': cleanTitle,
      'category': category,
      'location': location.trim(),
      'description': description.trim(),
      'featured': featured,
      'sort_order': sortOrder,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> setPublished(
    String id,
    bool published,
  ) async {
    if (published) {
      final row = await _db
          .from('web_projects')
          .select('cover_path')
          .eq('id', id)
          .single();

      final coverPath = row['cover_path'] as String?;

      if (coverPath == null || coverPath.trim().isEmpty) {
        throw StateError(
          'Debes seleccionar una fotografía de portada '
          'antes de publicar esta obra.',
        );
      }

      final image = await _db
          .from('web_project_images')
          .select('id')
          .eq('project_id', id)
          .eq('storage_path', coverPath)
          .maybeSingle();

      if (image == null) {
        throw StateError(
          'La portada seleccionada no está registrada '
          'en la galería de esta obra.',
        );
      }
    }

    await _db.from('web_projects').update({
      'published': published,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _db.from('web_projects').delete().eq('id', id);
  }
}
