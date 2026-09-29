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
        activities,
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
        (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo(
          (b['sort_order'] as num?)?.toInt() ?? 0,
        ),
      );

      final items = itemRows.map((item) {
        return QuoteItem.fromJson(item);
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
        DateTime.tryParse(
              row['quote_date']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now(),
        items,
        netAmount: double.tryParse(row['net_amount']?.toString() ?? '') ?? 0,
      );
    }).toList();
  }

  static Future<void> save(Quote quote) async {
    if (quote.id.trim().isEmpty) {
      throw ArgumentError(
        'La cotización no tiene identificador.',
      );
    }

    if (quote.netAmount < 0 || !quote.netAmount.isFinite) {
      throw ArgumentError(
        'El monto neto de la cotización es inválido.',
      );
    }

    if (quote.items.isEmpty) {
      throw ArgumentError(
        'Debes agregar al menos una partida.',
      );
    }

    final header = <String, dynamic>{
      'id': quote.id,
      'client_id': quote.clientId.trim(),
      'client_name': quote.client.trim(),
      'project_id': quote.projectId.trim(),
      'project_name': quote.projectName.trim(),
      'email': quote.email.trim(),
      'address': quote.address.trim(),
      'notes': quote.notes.trim(),
      'payment': quote.payment.trim(),
      'status': quote.status,
      'quote_date': quote.date.toUtc().toIso8601String(),
      'net_amount': quote.netAmount,
    };

    final items = quote.items.map((item) {
      return <String, dynamic>{
        'description': item.description.trim(),
        'activities': item.activities
            .map((activity) => activity.trim())
            .where((activity) => activity.isNotEmpty)
            .toList(),

        // Compatibilidad con las columnas antiguas.
        'unit': 'GL',
        'quantity': 0,
        'price': 0,
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

  static Future<void> saveAll(List<Quote> quotes) async {
    for (final quote in quotes) {
      await save(quote);
    }
  }
}
