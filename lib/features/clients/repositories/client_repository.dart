import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';

class ClientRepository {
  static const String _storageKey = 'clients';

  static Future<List<Client>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final raw = prefs.getString(_storageKey) ?? '[]';

      return (jsonDecode(raw) as List)
          .map(
            (item) => Client.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(
    List<Client> clients,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(
        clients.map((client) => client.toJson()).toList(),
      ),
    );
  }
}
