import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

class QuoteRepository {
  static const String _storageKey = 'quotes';

  static Future<List<Quote>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final raw = prefs.getString(_storageKey) ?? '[]';

      return (jsonDecode(raw) as List)
          .map(
            (item) => Quote.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(
    List<Quote> quotes,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(
        quotes.map((quote) => quote.toJson()).toList(),
      ),
    );
  }
}
