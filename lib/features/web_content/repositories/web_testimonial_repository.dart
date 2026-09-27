import 'package:supabase_flutter/supabase_flutter.dart';

class WebTestimonial {
  final String id;
  final String customerName;
  final String? customerRole;
  final String testimonial;
  final int? rating;
  final int sortOrder;
  final bool authorized;
  final bool published;

  const WebTestimonial({
    required this.id,
    required this.customerName,
    required this.customerRole,
    required this.testimonial,
    required this.rating,
    required this.sortOrder,
    required this.authorized,
    required this.published,
  });

  factory WebTestimonial.fromJson(Map<String, dynamic> json) {
    return WebTestimonial(
      id: json['id'] as String,
      customerName: json['customer_name'] as String,
      customerRole: json['customer_role'] as String?,
      testimonial: json['testimonial'] as String,
      rating: (json['rating'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      authorized: json['authorized'] as bool? ?? false,
      published: json['published'] as bool? ?? false,
    );
  }
}

class WebTestimonialRepository {
  WebTestimonialRepository._();

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<WebTestimonial>> getAll() async {
    final rows = await _db
        .from('web_testimonials')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return rows.map((row) => WebTestimonial.fromJson(row)).toList();
  }

  static Future<List<WebTestimonial>> getPublished() async {
    final rows = await _db
        .from('web_testimonials')
        .select()
        .eq('authorized', true)
        .eq('published', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return rows.map((row) => WebTestimonial.fromJson(row)).toList();
  }

  static Future<void> save({
    String? id,
    required String customerName,
    required String? customerRole,
    required String testimonial,
    required int? rating,
    required int sortOrder,
    required bool authorized,
    required bool published,
  }) async {
    final name = customerName.trim();
    final content = testimonial.trim();
    final role = customerRole?.trim();

    if (name.length < 2 || name.length > 120) {
      throw ArgumentError(
        'El nombre debe tener entre 2 y 120 caracteres.',
      );
    }

    if (content.length < 10 || content.length > 1500) {
      throw ArgumentError(
        'El testimonio debe tener entre 10 y 1500 caracteres.',
      );
    }

    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError('La valoración debe estar entre 1 y 5.');
    }

    if (published && !authorized) {
      throw ArgumentError(
        'No puedes publicar un testimonio sin autorización.',
      );
    }

    final data = <String, dynamic>{
      'customer_name': name,
      'customer_role': role == null || role.isEmpty ? null : role,
      'testimonial': content,
      'rating': rating,
      'sort_order': sortOrder,
      'authorized': authorized,
      'published': published,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (id == null) {
      await _db.from('web_testimonials').insert(data);
    } else {
      await _db
          .from('web_testimonials')
          .update(data)
          .eq('id', id)
          .select('id')
          .single();
    }
  }

  static Future<void> delete(String id) async {
    await _db
        .from('web_testimonials')
        .delete()
        .eq('id', id)
        .select('id')
        .single();
  }
}
