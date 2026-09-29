class QuoteItem {
  /// Nombre de la partida: Pintura, Terminaciones, etc.
  String description;

  /// Trabajos incluidos en la partida.
  List<String> activities;

  // Campos heredados. Se mantienen temporalmente para que
  // otras partes del proyecto puedan seguir compilando.
  String unit;
  double quantity;
  double price;

  QuoteItem(
    this.description,
    this.unit,
    this.quantity,
    this.price, {
    List<String>? activities,
  }) : activities = activities ?? [];

  /// Constructor para las nuevas partidas.
  factory QuoteItem.partida({
    String description = '',
    List<String>? activities,
  }) {
    return QuoteItem(
      description,
      'GL',
      0,
      0,
      activities: activities,
    );
  }

  /// Solo para compatibilidad con código anterior.
  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
        'description': description,
        'activities': activities,
        'unit': unit,
        'quantity': quantity,
        'price': price,
      };

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'];

    return QuoteItem(
      json['description']?.toString() ?? '',
      json['unit']?.toString() ?? 'GL',
      (json['quantity'] as num?)?.toDouble() ?? 0,
      (json['price'] as num?)?.toDouble() ?? 0,
      activities: rawActivities is List
          ? rawActivities.map((value) => value.toString()).toList()
          : [],
    );
  }

  QuoteItem copy() {
    return QuoteItem(
      description,
      unit,
      quantity,
      price,
      activities: List<String>.from(activities),
    );
  }
}
