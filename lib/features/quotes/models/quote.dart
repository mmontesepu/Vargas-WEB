import 'quote_item.dart';

class Quote {
  String id;
  String client;
  String email;
  String address;
  String notes;
  String payment;
  String status;

  DateTime date;

  List<QuoteItem> items;

  Quote(
    this.id,
    this.client,
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
        'client': client,
        'email': email,
        'address': address,
        'notes': notes,
        'payment': payment,
        'status': status,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      json['id'],
      json['client'],
      json['email'] ?? '',
      json['address'] ?? '',
      json['notes'] ?? '',
      json['payment'] ?? '',
      json['status'] ?? 'Borrador',
      DateTime.parse(json['date']),
      (json['items'] as List)
          .map(
            (item) => QuoteItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}
