import 'dart:convert';

import 'package:http/http.dart' as http;

class QuoteRequestResult {
  final String message;

  const QuoteRequestResult({
    required this.message,
  });
}

class QuoteRequestRepository {
  QuoteRequestRepository._();

  // Reemplazar con el endpoint real de Formspree.
  static const String _formEndpoint = 'https://formspree.io/f/mppwynkz';

  static Future<QuoteRequestResult> send({
    required String name,
    required String phone,
    required String email,
    required String service,
    required String message,
  }) async {
    if (_formEndpoint.endsWith('/XXXXXXXX')) {
      throw StateError(
        'Falta configurar el identificador de Formspree.',
      );
    }

    final response = await http
        .post(
          Uri.parse(_formEndpoint),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'service': service.trim(),
            'message': message.trim(),
            '_subject': 'Nueva solicitud de cotización - Vargas SPA',
          }),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Conservamos el código HTTP para gestionar el resultado.
    }

    if (response.statusCode == 429) {
      throw StateError(
        'Se alcanzó el límite temporal de solicitudes. '
        'Inténtalo nuevamente más tarde.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'No fue posible enviar la cotización.';

      final errors = data['errors'];

      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;

        if (first is Map && first['message'] != null) {
          errorMessage = first['message'].toString();
        }
      } else if (data['error'] != null) {
        errorMessage = data['error'].toString();
      }

      throw StateError(errorMessage);
    }

    return const QuoteRequestResult(
      message: 'Tu solicitud fue enviada correctamente a Vargas SPA. '
          'Nos pondremos en contacto contigo.',
    );
  }
}
