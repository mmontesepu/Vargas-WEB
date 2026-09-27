import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client.dart';

class ClientRepository {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static const String _table = 'clients';

  /// Obtiene todos los clientes registrados en Supabase.
  static Future<List<Client>> getAll() async {
    final response = await _supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return response.map((row) {
      return Client(
        id: row['id']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
        rut: row['rut']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        phone: row['phone']?.toString() ?? '',
        address: row['address']?.toString() ?? '',
        notes: row['notes']?.toString() ?? '',
        createdAt: DateTime.tryParse(
              row['created_at']?.toString() ?? '',
            ) ??
            DateTime.now(),
      );
    }).toList();
  }

  /// Guarda los clientes existentes o actualizados.
  ///
  /// Mantiene la firma anterior para conservar compatibilidad
  /// con las pantallas actuales.
  static Future<void> saveAll(List<Client> clients) async {
    if (clients.isEmpty) return;

    final rows = clients.map((client) {
      return {
        'id': client.id,
        'name': client.name.trim(),
        'rut': client.rut.trim(),
        'email': client.email.trim(),
        'phone': client.phone.trim(),
        'address': client.address.trim(),
        'notes': client.notes.trim(),
        'created_at': client.createdAt.toUtc().toIso8601String(),
      };
    }).toList();

    await _supabase.from(_table).upsert(
          rows,
          onConflict: 'id',
        );
  }

  static Future<void> delete(String clientId) async {
    if (clientId.trim().isEmpty) {
      throw ArgumentError('El cliente no tiene un identificador válido.');
    }

    await _supabase.from(_table).delete().eq('id', clientId);
  }
}
