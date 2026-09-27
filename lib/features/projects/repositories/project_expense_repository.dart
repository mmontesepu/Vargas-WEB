import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_expense.dart';

class ProjectExpenseRepository {
  static SupabaseClient get _db => Supabase.instance.client;

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static ProjectExpense _fromRow(Map<String, dynamic> row) {
    return ProjectExpense(
      id: row['id']?.toString() ?? '',
      projectId: row['project_id']?.toString() ?? '',
      date: DateTime.parse(row['expense_date'].toString()),
      category: row['category']?.toString() ?? 'Otros',
      description: row['description']?.toString() ?? '',
      supplier: row['supplier']?.toString() ?? '',
      amount: _number(row['amount']),
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }

  static Map<String, dynamic> _toRow(ProjectExpense expense) {
    return {
      'id': expense.id,
      'project_id': expense.projectId,
      'expense_date': expense.date.toIso8601String(),
      'category': expense.category,
      'description': expense.description,
      'supplier': expense.supplier,
      'amount': expense.amount,
      'created_at': expense.createdAt.toIso8601String(),
    };
  }

  static void _validate(ProjectExpense expense) {
    if (expense.id.trim().isEmpty || expense.projectId.trim().isEmpty) {
      throw ArgumentError(
        'El gasto debe tener un ID y un proyecto válido.',
      );
    }

    if (expense.description.trim().isEmpty) {
      throw ArgumentError('Debes ingresar una descripción.');
    }

    if (!expense.amount.isFinite || expense.amount <= 0) {
      throw ArgumentError(
        'El monto debe ser mayor que cero.',
      );
    }
  }

  static Future<List<ProjectExpense>> getAll() async {
    final rows = await _db
        .from('project_expenses')
        .select()
        .order('expense_date', ascending: false);

    return rows.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  }

  static Future<List<ProjectExpense>> getByProject(
    String projectId,
  ) async {
    final rows = await _db
        .from('project_expenses')
        .select()
        .eq('project_id', projectId)
        .order('expense_date', ascending: false);

    return rows.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  }

  static Future<void> add(ProjectExpense expense) async {
    _validate(expense);

    await _db.from('project_expenses').insert(
          _toRow(expense),
        );
  }

  static Future<void> update(ProjectExpense expense) async {
    _validate(expense);

    final data = _toRow(expense)
      ..remove('id')
      ..remove('project_id')
      ..remove('created_at');

    final updated = await _db
        .from('project_expenses')
        .update(data)
        .eq('id', expense.id)
        .eq('project_id', expense.projectId)
        .select('id');

    if (updated.isEmpty) {
      throw StateError(
        'No se encontró el gasto que deseas editar.',
      );
    }
  }

  static Future<void> delete({
    required String id,
    required String projectId,
  }) async {
    final deleted = await _db
        .from('project_expenses')
        .delete()
        .eq('id', id)
        .eq('project_id', projectId)
        .select('id');

    if (deleted.isEmpty) {
      throw StateError(
        'No se encontró el gasto que deseas eliminar.',
      );
    }
  }

  static Future<double> totalByProject(
    String projectId,
  ) async {
    final expenses = await getByProject(projectId);

    return expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
  }

  // Compatibilidad temporal con posibles llamadas anteriores.
  // Guarda los registros recibidos, pero no elimina los ausentes.
  static Future<void> saveAll(
    List<ProjectExpense> expenses,
  ) async {
    for (final expense in expenses) {
      _validate(expense);
    }

    if (expenses.isEmpty) return;

    await _db.from('project_expenses').upsert(
          expenses.map(_toRow).toList(),
          onConflict: 'id',
        );
  }
}
