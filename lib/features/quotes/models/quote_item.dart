class QuoteItem {
  String description;
  String unit;
  double quantity;
  double price;

  QuoteItem(
    this.description,
    this.unit,
    this.quantity,
    this.price,
  );

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'price': price,
      };

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      json['description'] ?? '',
      json['unit'] ?? 'GL',
      (json['quantity'] as num).toDouble(),
      (json['price'] as num).toDouble(),
    );
  }
}
