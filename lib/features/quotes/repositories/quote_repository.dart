import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quote.dart';
import '../models/quote_item.dart';

class QuoteRepository {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<Quote>> getAll() async {
    final rows = await _supabase.from('quotes').select('''
          *,
          quote_items (
            description,
            unit,
            quantity,
            price,
            sort_order
          )
        ''').order('quote_date', ascending: false);

    return rows.map((row) {
      final itemRows = List<Map<String, dynamic>>.from(
        row['quote_items'] ?? [],
      );

      itemRows.sort(
        (a, b) => (a['sort_order'] as num).compareTo(
          b['sort_order'] as num,
        ),
      );

      final items = itemRows.map((item) {
        return QuoteItem(
          item['description']?.toString() ?? '',
          item['unit']?.toString() ?? 'GL',
          (item['quantity'] as num).toDouble(),
          (item['price'] as num).toDouble(),
        );
      }).toList();

      return Quote(
        row['id']?.toString() ?? '',
        row['client_id']?.toString() ?? '',
        row['client_name']?.toString() ?? '',
        row['project_id']?.toString() ?? '',
        row['project_name']?.toString() ?? '',
        row['email']?.toString() ?? '',
        row['address']?.toString() ?? '',
        row['notes']?.toString() ?? '',
        row['payment']?.toString() ?? '',
        row['status']?.toString() ?? 'Borrador',
        DateTime.parse(row['quote_date'].toString()).toLocal(),
        items,
      );
    }).toList();
  }

  static Future<void> save(Quote quote) async {
    if (quote.id.trim().isEmpty) {
      throw ArgumentError('La cotización no tiene identificador.');
    }

    final header = {
      'id': quote.id,
      'client_id': quote.clientId.trim(),
      'client_name': quote.client,
      'project_id': quote.projectId.trim(),
      'project_name': quote.projectName,
      'email': quote.email,
      'address': quote.address,
      'notes': quote.notes,
      'payment': quote.payment,
      'status': quote.status,
      'quote_date': quote.date.toUtc().toIso8601String(),
    };

    final items = quote.items.map((item) {
      return {
        'description': item.description,
        'unit': item.unit,
        'quantity': item.quantity,
        'price': item.price,
      };
    }).toList();

    await _supabase.rpc(
      'save_quote_with_items',
      params: {
        'p_quote': header,
        'p_items': items,
      },
    );
  }

  // Compatibilidad temporal con las pantallas existentes.
  static Future<void> saveAll(List<Quote> quotes) async {
    for (final quote in quotes) {
      await save(quote);
    }
  }
}
