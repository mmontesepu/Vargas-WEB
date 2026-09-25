class Project {
  String id;

  // Cliente
  String clientId;
  String clientName;

  // Cotización que originó el proyecto
  String sourceQuoteId;

  // Información de la obra
  String name;
  String address;
  String description;
  String status;

  // Planificación
  DateTime startDate;
  DateTime? estimatedEndDate;

  // Montos comerciales aprobados
  double contractedNet;
  double contractedTotal;

  // Presupuesto operativo de costos
  double budget;

  DateTime createdAt;

  Project({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.sourceQuoteId = '',
    required this.name,
    this.address = '',
    this.description = '',
    this.status = 'Planificación',
    required this.startDate,
    this.estimatedEndDate,
    this.contractedNet = 0,
    this.contractedTotal = 0,
    this.budget = 0,
    required this.createdAt,
  });

  bool get hasSourceQuote => sourceQuoteId.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'sourceQuoteId': sourceQuoteId,
        'name': name,
        'address': address,
        'description': description,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'estimatedEndDate': estimatedEndDate?.toIso8601String(),
        'contractedNet': contractedNet,
        'contractedTotal': contractedTotal,
        'budget': budget,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',

      // Compatibilidad con proyectos antiguos.
      sourceQuoteId: json['sourceQuoteId'] ?? '',

      name: json['name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Planificación',

      startDate: DateTime.tryParse(
            json['startDate'] ?? '',
          ) ??
          DateTime.now(),

      estimatedEndDate: json['estimatedEndDate'] != null
          ? DateTime.tryParse(
              json['estimatedEndDate'],
            )
          : null,

      // Los proyectos antiguos no tienen estos montos.
      contractedNet: (json['contractedNet'] as num?)?.toDouble() ?? 0,

      contractedTotal: (json['contractedTotal'] as num?)?.toDouble() ?? 0,

      budget: (json['budget'] as num?)?.toDouble() ?? 0,

      createdAt: DateTime.tryParse(
            json['createdAt'] ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
