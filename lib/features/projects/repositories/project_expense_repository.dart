import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_expense.dart';

class ProjectExpenseRepository {
  static const String _storageKey = 'project_expenses';

  static Future<List<ProjectExpense>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map(
          (item) => ProjectExpense.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<List<ProjectExpense>> getByProject(
    String projectId,
  ) async {
    final expenses = await getAll();

    return expenses.where((expense) => expense.projectId == projectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveAll(
    List<ProjectExpense> expenses,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      expenses.map((expense) => expense.toJson()).toList(),
    );

    final saved = await prefs.setString(_storageKey, encoded);

    if (!saved) {
      throw StateError(
        'No se pudieron guardar los gastos del proyecto.',
      );
    }
  }

  static void _validate(ProjectExpense expense) {
    if (expense.id.trim().isEmpty || expense.projectId.trim().isEmpty) {
      throw ArgumentError(
        'El gasto debe tener un ID y un proyecto válido.',
      );
    }

    if (expense.description.trim().isEmpty) {
      throw ArgumentError(
        'Debes ingresar una descripción.',
      );
    }

    if (!expense.amount.isFinite || expense.amount <= 0) {
      throw ArgumentError(
        'El monto debe ser mayor que cero.',
      );
    }
  }

  static Future<void> add(
    ProjectExpense expense,
  ) async {
    _validate(expense);

    final expenses = await getAll();

    if (expenses.any((item) => item.id == expense.id)) {
      throw StateError(
        'Ya existe un gasto con este identificador.',
      );
    }

    expenses.add(expense);
    await saveAll(expenses);
  }

  static Future<void> update(
    ProjectExpense expense,
  ) async {
    _validate(expense);

    final expenses = await getAll();

    final index = expenses.indexWhere(
      (item) => item.id == expense.id && item.projectId == expense.projectId,
    );

    if (index == -1) {
      throw StateError(
        'No se encontró el gasto que deseas editar.',
      );
    }

    expenses[index] = expense;
    await saveAll(expenses);
  }

  static Future<void> delete({
    required String id,
    required String projectId,
  }) async {
    final expenses = await getAll();

    final index = expenses.indexWhere(
      (item) => item.id == id && item.projectId == projectId,
    );

    if (index == -1) {
      throw StateError(
        'No se encontró el gasto que deseas eliminar.',
      );
    }

    expenses.removeAt(index);
    await saveAll(expenses);
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
}
