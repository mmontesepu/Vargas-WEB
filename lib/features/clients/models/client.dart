class Client {
  String id;
  String name;
  String rut;
  String email;
  String phone;
  String address;
  String notes;
  DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    this.rut = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rut': rut,
        'email': email,
        'phone': phone,
        'address': address,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rut: json['rut'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt'] ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
