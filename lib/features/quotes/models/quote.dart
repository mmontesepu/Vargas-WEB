import 'quote_item.dart';

class Quote {
  String id;

  // Relación con cliente
  String clientId;
  String client;

  // Relación con proyecto / obra
  String projectId;
  String projectName;

  String email;
  String address;
  String notes;
  String payment;
  String status;

  DateTime date;

  List<QuoteItem> items;

  Quote(
    this.id,
    this.clientId,
    this.client,
    this.projectId,
    this.projectName,
    this.email,
    this.address,
    this.notes,
    this.payment,
    this.status,
    this.date,
    this.items,
  );

  double get net {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get vat => (net * .19).roundToDouble();

  double get total => net + vat;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'client': client,
        'projectId': projectId,
        'projectName': projectName,
        'email': email,
        'address': address,
        'notes': notes,
        'payment': payment,
        'status': status,
        'date': date.toIso8601String(),
        'items': items
            .map(
              (item) => item.toJson(),
            )
            .toList(),
      };

  factory Quote.fromJson(
    Map<String, dynamic> json,
  ) {
    return Quote(
      json['id'] ?? '',

      json['clientId'] ?? '',
      json['client'] ?? '',

      // Compatibilidad con cotizaciones antiguas.
      // Si no existen estos campos simplemente
      // quedarán vacíos.
      json['projectId'] ?? '',
      json['projectName'] ?? '',

      json['email'] ?? '',
      json['address'] ?? '',
      json['notes'] ?? '',
      json['payment'] ?? '',
      json['status'] ?? 'Borrador',

      DateTime.tryParse(
            json['date'] ?? '',
          ) ??
          DateTime.now(),

      (json['items'] as List? ?? [])
          .map(
            (item) => QuoteItem.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList(),
    );
  }
}
