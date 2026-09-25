class ProjectExpense {
  final String id;
  final String projectId;

  final DateTime date;
  final String category;
  final String description;
  final String supplier;

  final double amount;
  final DateTime createdAt;

  const ProjectExpense({
    required this.id,
    required this.projectId,
    required this.date,
    required this.category,
    required this.description,
    this.supplier = '',
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'supplier': supplier,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProjectExpense.fromJson(Map<String, dynamic> json) {
    return ProjectExpense(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      category: json['category']?.toString() ?? 'Otros',
      description: json['description']?.toString() ?? '',
      supplier: json['supplier']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
