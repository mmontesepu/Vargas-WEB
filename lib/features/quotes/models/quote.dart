import 'quote_item.dart';

class Quote {
  String id;

  // Cliente
  String clientId;
  String client;

  // Proyecto / obra
  String projectId;
  String projectName;

  String email;
  String address;
  String notes;
  String payment;
  String status;

  DateTime date;

  /// Partidas y actividades de la cotización.
  List<QuoteItem> items;

  /// Monto neto general. No depende de los precios por partida.
  double netAmount;

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
    this.items, {
    double? netAmount,
  }) : netAmount = netAmount ??
            items.fold<double>(
              0,
              (sum, item) => sum + item.total,
            );

  double get net => netAmount;

  double get vat => (net * 0.19).roundToDouble();

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
        'netAmount': netAmount,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory Quote.fromJson(Map<String, dynamic> json) {
    final parsedItems = (json['items'] as List? ?? [])
        .map(
          (item) => QuoteItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final rawNet = json['netAmount'] ?? json['net_amount'];

    return Quote(
      json['id']?.toString() ?? '',
      json['clientId']?.toString() ?? '',
      json['client']?.toString() ?? '',
      json['projectId']?.toString() ?? '',
      json['projectName']?.toString() ?? '',
      json['email']?.toString() ?? '',
      json['address']?.toString() ?? '',
      json['notes']?.toString() ?? '',
      json['payment']?.toString() ?? '',
      json['status']?.toString() ?? 'Borrador',
      DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      parsedItems,
      netAmount: rawNet == null ? null : double.tryParse(rawNet.toString()),
    );
  }
}
