import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/project.dart';
import '../models/project_expense.dart';
import '../repositories/project_expense_repository.dart';

import '../../../core/formatters/clp_input_formatter.dart';

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
  static const _categories = <String>[
    'Materiales',
    'Mano de obra',
    'Transporte',
    'Otros',
  ];

  List<ProjectExpense> _expenses = [];
  bool _loading = true;
  String? _loadError;

  String _money(num value) {
    final formatted = value.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
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
    try {
      final expenses = await ProjectExpenseRepository.getByProject(
        widget.project.id,
      );

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'No se pudieron cargar los gastos: $error';
      });
    }
  }

  double get _totalExpenses {
    return _expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  Map<String, double> get _categoryTotals {
    final totals = {
      for (final category in _categories) category: 0.0,
    };

    for (final expense in _expenses) {
      final category =
          totals.containsKey(expense.category) ? expense.category : 'Otros';

      totals[category] = totals[category]! + expense.amount;
    }

    return totals;
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountCard(
    String title,
    double value, {
    Color? valueColor,
    String? hint,
    required double width,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 5),
                Tooltip(
                  message: hint,
                  child: const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(value),
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialSummary(double availableWidth) {
    final project = widget.project;
    final remainingBudget = project.budget - _totalExpenses;
    final currentMargin = project.contractedNet - _totalExpenses;

    const gap = 10.0;

    final columns = availableWidth >= 850
        ? 4
        : availableWidth >= 440
            ? 2
            : 1;

    final cardWidth = (availableWidth - gap * (columns - 1)) / columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _amountCard(
              'Neto contratado',
              project.contractedNet,
              width: cardWidth,
              valueColor: gold,
              hint: 'Valor de venta aprobado, sin IVA.',
            ),
            _amountCard(
              'Presupuesto estimado de costos',
              project.budget,
              width: cardWidth,
              hint:
                  'Estimación inicial para ejecutar la obra. No corresponde a gastos reales.',
            ),
            _amountCard(
              'Gastos reales',
              _totalExpenses,
              width: cardWidth,
              hint: 'Suma de los gastos registrados en esta obra.',
            ),
            _amountCard(
              'Saldo presupuestario',
              remainingBudget,
              width: cardWidth,
              valueColor:
                  remainingBudget < 0 ? Colors.redAccent : Colors.greenAccent,
              hint: 'Presupuesto estimado menos gastos reales.',
            ),
          ],
        ),
        if (project.hasSourceQuote) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: _panelDecoration(),
            child: Wrap(
              spacing: 12,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Margen bruto actual (provisional)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Tooltip(
                      message:
                          'Venta neta menos gastos registrados. No representa la utilidad final.',
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                Text(
                  _money(currentMargin),
                  style: TextStyle(
                    color: currentMargin < 0
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _budgetUsage() {
    final budget = widget.project.budget;
    final spent = _totalExpenses;

    final percent = budget > 0 ? spent / budget * 100 : null;
    final exceeded = budget > 0 && spent > budget;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Utilización del presupuesto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (percent != null)
                Text(
                  '${percent.toStringAsFixed(1)} %',
                  style: TextStyle(
                    color: exceeded ? Colors.redAccent : gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            percent == null
                ? 'Sin presupuesto estimado.'
                : 'Gastos reales respecto del presupuesto inicial.',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percent == null ? 0 : (percent / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                exceeded ? Colors.redAccent : gold,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              Text(
                'Gastado: ${_money(spent)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                exceeded
                    ? 'Exceso: ${_money(spent - budget)}'
                    : 'Disponible: ${_money(budget - spent)}',
                style: TextStyle(
                  color: exceeded ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categorySummary() {
    final totals = _categoryTotals;
    final total = _totalExpenses;

    final icons = <String, IconData>{
      'Materiales': Icons.inventory_2_outlined,
      'Mano de obra': Icons.engineering_outlined,
      'Transporte': Icons.local_shipping_outlined,
      'Otros': Icons.receipt_long_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Gastos por categoría',
            subtitle: 'Distribución de los gastos registrados.',
          ),
          const SizedBox(height: 13),
          if (total == 0)
            const Text(
              'Aún no hay gastos para distribuir.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            )
          else
            ..._categories.map((category) {
              final amount = totals[category]!;
              final ratio = amount / total;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          icons[category],
                          size: 15,
                          color: gold,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _money(amount),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${(ratio * 100).toStringAsFixed(1)}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(gold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: Colors.white12, height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total registrado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _money(total),
                style: const TextStyle(
                  color: gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analysisSection(double availableWidth) {
    final wide = availableWidth >= 760;

    if (!wide) {
      return Column(
        children: [
          _budgetUsage(),
          const SizedBox(height: 10),
          _categorySummary(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _budgetUsage(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _categorySummary(),
        ),
      ],
    );
  }

  Widget _expenseItem(
    ProjectExpense expense,
    bool compact,
  ) {
    final details = '${expense.category} · ${_date(expense.date)}'
        '${expense.supplier.isNotEmpty ? ' · ${expense.supplier}' : ''}';

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _money(expense.amount),
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Editar gasto',
                  onPressed: () => _openExpenseDialog(expense),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Eliminar gasto',
                  onPressed: () => _deleteExpense(expense),
                  icon: const Icon(Icons.delete_outline, size: 19),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: gold,
            size: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _money(expense.amount),
            style: const TextStyle(
              color: gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Editar gasto',
            onPressed: () => _openExpenseDialog(expense),
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Eliminar gasto',
            onPressed: () => _deleteExpense(expense),
            icon: const Icon(Icons.delete_outline, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _expensesSection(double availableWidth) {
    final compact = availableWidth < 560;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                'Gastos de la obra',
                subtitle:
                    '${_expenses.length} movimiento${_expenses.length == 1 ? '' : 's'} registrado${_expenses.length == 1 ? '' : 's'}',
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openExpenseDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo gasto'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: _panelDecoration(),
          child: _expenses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(26),
                  child: Center(
                    child: Text(
                      'Todavía no hay gastos registrados.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _expenses.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          color: Colors.white12,
                        ),
                      _expenseItem(_expenses[i], compact),
                    ],
                  ],
                ),
        ),
      ],
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

    if (!mounted || _loadError != null) return;

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

      if (!mounted || _loadError != null) return;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadExpenses,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth < 600 ? 14.0 : 24.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 1200,
                          ),
                          child: LayoutBuilder(
                            builder: (context, contentConstraints) {
                              final width = contentConstraints.maxWidth;

                              final compactHeader = width < 540;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (compactHeader)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _projectHeading(project),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.icon(
                                            onPressed: () =>
                                                _openExpenseDialog(),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Nuevo gasto'),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _projectHeading(project),
                                        ),
                                        const SizedBox(width: 16),
                                        FilledButton.icon(
                                          onPressed: () => _openExpenseDialog(),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Nuevo gasto'),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 18),
                                  _financialSummary(width),
                                  const SizedBox(height: 12),
                                  _analysisSection(width),
                                  const SizedBox(height: 22),
                                  _expensesSection(width),
                                  const SizedBox(height: 18),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _projectHeading(Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 9,
          runSpacing: 3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              project.clientName,
              style: const TextStyle(
                color: gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (project.hasSourceQuote)
              Text(
                '· Cotización: ${project.sourceQuoteId}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
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

      _amountController.text = ClpInputFormatter.format(
        expense.amount.round().toString(),
      );

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final amount = ClpInputFormatter.parse(_amountController.text);

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
                  inputFormatters: [
                    const ClpInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto del costo',
                    prefixText: '\$ ',
                  ),
                  validator: (value) {
                    final amount = ClpInputFormatter.parse(value ?? '');

                    if (!amount.isFinite || amount <= 0) {
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

                          if (!mounted || picked == null) return;

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
          onPressed: _saving ? null : () => Navigator.pop(context, false),
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
