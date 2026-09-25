import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/project.dart';
import '../models/project_expense.dart';
import '../repositories/project_expense_repository.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<ProjectExpense> _expenses = [];
  bool _loading = true;

  String _money(num value) {
    final formatted = value.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    return '\$$formatted';
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await ProjectExpenseRepository.getByProject(
      widget.project.id,
    );

    if (!mounted) return;

    setState(() {
      _expenses = expenses;
      _loading = false;
    });
  }

  double get _totalExpenses {
    return _expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
  }

  Widget _amountCard(
    String title,
    double value, {
    Color? valueColor,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _money(value),
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExpenseDialog([
    ProjectExpense? existing,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExpenseDialog(
        projectId: widget.project.id,
        existing: existing,
      ),
    );

    if (!mounted || saved != true) return;

    await _loadExpenses();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Gasto registrado correctamente'
              : 'Gasto actualizado correctamente',
        ),
      ),
    );
  }

  Future<void> _deleteExpense(
    ProjectExpense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Deseas eliminar el gasto "${expense.description}" '
          'por ${_money(expense.amount)}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await ProjectExpenseRepository.delete(
        id: expense.id,
        projectId: widget.project.id,
      );

      await _loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto eliminado correctamente'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el gasto: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    final remainingBudget = project.budget - _totalExpenses;

    final currentMargin = project.contractedNet - _totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.clientName,
                        style: const TextStyle(
                          color: gold,
                        ),
                      ),
                      if (project.hasSourceQuote) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Cotización: ${project.sourceQuoteId}',
                          style: const TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _amountCard(
                            'Neto contratado',
                            project.contractedNet,
                            valueColor: gold,
                          ),
                          _amountCard(
                            'Presupuesto de costos',
                            project.budget,
                          ),
                          _amountCard(
                            'Gastos reales',
                            _totalExpenses,
                          ),
                          _amountCard(
                            'Saldo presupuestario',
                            remainingBudget,
                            valueColor: remainingBudget < 0
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                        ],
                      ),
                      if (project.hasSourceQuote) ...[
                        const SizedBox(height: 14),
                        _amountCard(
                          'Margen bruto actual (provisional)',
                          currentMargin,
                          valueColor: currentMargin < 0
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Gastos de la obra',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openExpenseDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo gasto'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_expenses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(45),
                          decoration: BoxDecoration(
                            color: panel,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Todavía no hay gastos registrados.',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._expenses.map(
                          (expense) => Card(
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.receipt_long_outlined,
                                color: gold,
                              ),
                              title: Text(
                                expense.description,
                              ),
                              subtitle: Text(
                                '${expense.category} · '
                                '${_date(expense.date)}'
                                '${expense.supplier.isNotEmpty ? ' · ${expense.supplier}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _money(expense.amount),
                                    style: const TextStyle(
                                      color: gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    tooltip: 'Editar gasto',
                                    onPressed: () => _openExpenseDialog(
                                      expense,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar gasto',
                                    onPressed: () => _deleteExpense(
                                      expense,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ======================================================
// FORMULARIO DE CREACIÓN Y EDICIÓN DE GASTOS
// ======================================================

class _ExpenseDialog extends StatefulWidget {
  final String projectId;
  final ProjectExpense? existing;

  const _ExpenseDialog({
    required this.projectId,
    this.existing,
  });

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();

  final _supplierController = TextEditingController();

  final _amountController = TextEditingController();

  String _category = 'Materiales';
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final expense = widget.existing;

    if (expense != null) {
      _descriptionController.text = expense.description;

      _supplierController.text = expense.supplier;

      _amountController.text = expense.amount.round().toString();

      _category = expense.category;
      _selectedDate = expense.date;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _supplierController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final amount = double.parse(
      _amountController.text.trim().replaceAll('.', ''),
    );

    final existing = widget.existing;

    final expense = ProjectExpense(
      id: existing?.id ?? 'EXP-${DateTime.now().microsecondsSinceEpoch}',
      projectId: widget.projectId,
      date: _selectedDate,
      category: _category,
      description: _descriptionController.text.trim(),
      supplier: _supplierController.text.trim(),
      amount: amount,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (existing == null) {
        await ProjectExpenseRepository.add(expense);
      } else {
        await ProjectExpenseRepository.update(expense);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el gasto: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Registrar gasto' : 'Editar gasto',
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Materiales',
                      child: Text('Materiales'),
                    ),
                    DropdownMenuItem(
                      value: 'Mano de obra',
                      child: Text('Mano de obra'),
                    ),
                    DropdownMenuItem(
                      value: 'Transporte',
                      child: Text('Transporte'),
                    ),
                    DropdownMenuItem(
                      value: 'Otros',
                      child: Text('Otros'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _category = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una descripción';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _supplierController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor (opcional)',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto del costo',
                    prefixText: '\$ ',
                  ),
                  validator: (value) {
                    final normalized = (value ?? '').trim().replaceAll('.', '');

                    final amount = double.tryParse(normalized);

                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Ingresa un monto válido';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (!mounted || picked == null) {
                            return;
                          }

                          setState(() {
                            _selectedDate = picked;
                          });
                        },
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                  ),
                  label: Text(
                    'Fecha: ${_date(_selectedDate)}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(
                    context,
                    false,
                  ),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? 'Guardando...'
                : widget.existing == null
                    ? 'Guardar gasto'
                    : 'Actualizar gasto',
          ),
        ),
      ],
    );
  }
}
