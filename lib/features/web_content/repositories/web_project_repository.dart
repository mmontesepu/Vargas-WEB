
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/web_project.dart';

class WebProjectRepository {
  WebProjectRepository._();

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<WebProject>> getAll() async {
    final rows = await _db
        .from('web_projects')
        .select()
        .order('created_at', ascending: false);

    return rows
        .map((row) => WebProject.fromJson(row))
        .toList();
  }

  static Future<WebProject> create({
    required String title,
    required String category,
    required String location,
    required String description,
    bool featured = false,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('El título es obligatorio.');
    }

    final row = await _db.from('web_projects').insert({
      'title': cleanTitle,
      'category': category,
      'location': location.trim(),
      'description': description.trim(),
      'featured': featured,
      'published': false,
    }).select().single();

    return WebProject.fromJson(row);
  }

  static Future<void> update({
    required String id,
    required String title,
    required String category,
    required String location,
    required String description,
    required bool featured,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('El título es obligatorio.');
    }

    await _db.from('web_projects').update({
      'title': cleanTitle,
      'category': category,
      'location': location.trim(),
      'description': description.trim(),
      'featured': featured,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> setPublished(
    String id,
    bool published,
  ) async {
    await _db.from('web_projects').update({
      'published': published,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _db.from('web_projects').delete().eq('id', id);
  }
}
