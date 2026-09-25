import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../clients/models/client.dart';
import '../../clients/repositories/client_repository.dart';
import '../models/project.dart';

import '../repositories/project_repository.dart';

import '../../quotes/models/quote.dart';

class ProjectEditorPage extends StatefulWidget {
  final Project? existing;
  final Quote? sourceQuote;

  const ProjectEditorPage({
    super.key,
    this.existing,
    this.sourceQuote,
  }) : assert(
          existing == null || sourceQuote == null,
          'No se puede editar un proyecto y crear desde una cotización al mismo tiempo.',
        );

  @override
  State<ProjectEditorPage> createState() => _ProjectEditorPageState();
}

class _ProjectEditorPageState extends State<ProjectEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _description;
  late final TextEditingController _budget;

  List<Client> _clients = [];

  String? _clientId;
  String _status = 'Planificación';

  late DateTime _startDate;
  DateTime? _estimatedEndDate;

  bool _loadingClients = true;

  String _buildQuoteDescription(Quote quote) {
    String money(num value) {
      final formatted = value.round().toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => '.',
          );

      return '\$$formatted';
    }

    final buffer = StringBuffer();

    buffer.writeln('ÍTEMS DE LA COTIZACIÓN ${quote.id}');
    buffer.writeln();

    for (var i = 0; i < quote.items.length; i++) {
      final item = quote.items[i];

      buffer.writeln('${i + 1}. ${item.description.trim()}');
      buffer.writeln(
        '   Cantidad: ${item.quantity} ${item.unit}',
      );
      buffer.writeln(
        '   Precio unitario: ${money(item.price)}',
      );
      buffer.writeln(
        '   Subtotal: ${money(item.total)}',
      );
      buffer.writeln();
    }

    if (quote.notes.trim().isNotEmpty) {
      buffer.writeln('OBSERVACIONES');
      buffer.writeln(quote.notes.trim());
    }

    return buffer.toString().trimRight();
  }

  @override
  void initState() {
    super.initState();

    final project = widget.existing;
    final quote = widget.sourceQuote;

    _name = TextEditingController(
      text: project?.name ?? '',
    );

    _address = TextEditingController(
      text: project?.address ?? quote?.address ?? '',
    );

    _description = TextEditingController(
      text: project?.description ??
          (quote == null ? '' : _buildQuoteDescription(quote)),
    );

    _budget = TextEditingController(
      text: project == null || project.budget == 0
          ? ''
          : project.budget.round().toString(),
    );

    _clientId = project?.clientId ?? widget.sourceQuote?.clientId;

    _status = project?.status ?? 'Planificación';

    _startDate = project?.startDate ?? DateTime.now();

    _estimatedEndDate = project?.estimatedEndDate;

    _loadClients();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    _budget.dispose();

    super.dispose();
  }

  Future<void> _loadClients() async {
    final clients = await ClientRepository.getAll();

    if (!mounted) return;

    setState(() {
      _clients = clients;

      if (_clientId != null &&
          !_clients.any(
            (client) => client.id == _clientId,
          )) {
        _clientId = null;
      }

      _loadingClients = false;
    });
  }

  Widget _commercialAmountCard(
    String label,
    double amount,
  ) {
    final formatted = amount.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$$formatted',
            style: const TextStyle(
              color: gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        title: Text(
          editing ? 'Editar proyecto' : 'Crear proyecto desde cotización',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing ? 'Información del proyecto' : 'Registrar proyecto',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Registra los datos principales de la obra o proyecto.',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 30),

                  //
                  // CLIENTE
                  //
                  const Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_loadingClients)
                    const LinearProgressIndicator()
                  else if (_clients.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: const Text(
                        'No existen clientes registrados. '
                        'Primero debes crear un cliente.',
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _clientId,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        prefixIcon: Icon(
                          Icons.business_outlined,
                        ),
                      ),
                      items: _clients
                          .map(
                            (client) => DropdownMenuItem<String>(
                              value: client.id,
                              child: Text(
                                client.rut.isEmpty
                                    ? client.name
                                    : '${client.name} • ${client.rut}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          widget.sourceQuote != null || widget.existing != null
                              ? null
                              : (value) {
                                  setState(() {
                                    _clientId = value;
                                  });
                                },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona un cliente';
                        }

                        return null;
                      },
                    ),

                  const SizedBox(height: 28),

                  //
                  // PROYECTO
                  //
                  const Text(
                    'Datos del proyecto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del proyecto *',
                      prefixIcon: Icon(
                        Icons.apartment_outlined,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de la obra',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(
                        Icons.notes_outlined,
                      ),
                    ),
                  ),

                  if (widget.sourceQuote != null) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Información comercial',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cotización de origen: ${widget.sourceQuote!.id}',
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 600;

                        final netCard = _commercialAmountCard(
                          'Neto contratado',
                          widget.sourceQuote!.net,
                        );

                        final totalCard = _commercialAmountCard(
                          'Total contratado (IVA incluido)',
                          widget.sourceQuote!.total,
                        );

                        if (compact) {
                          return Column(
                            children: [
                              netCard,
                              const SizedBox(height: 12),
                              totalCard,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: netCard),
                            const SizedBox(width: 12),
                            Expanded(child: totalCard),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 28),

                  //
                  // PLANIFICACIÓN
                  //
                  const Text(
                    'Planificación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      final compact = constraints.maxWidth < 600;

                      final start = _dateSelector(
                        title: 'Fecha de inicio',
                        date: _startDate,
                        onPressed: _selectStartDate,
                      );

                      final end = _dateSelector(
                        title: 'Fecha estimada de término',
                        date: _estimatedEndDate,
                        onPressed: _selectEndDate,
                        allowClear: true,
                      );

                      if (compact) {
                        return Column(
                          children: [
                            start,
                            const SizedBox(
                              height: 12,
                            ),
                            end,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: start,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: end,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      final compact = constraints.maxWidth < 600;

                      final statusField = DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: Icon(
                            Icons.flag_outlined,
                          ),
                        ),
                        items: [
                          'Planificación',
                          'En ejecución',
                          'Pausado',
                          'Finalizado',
                          'Cancelado',
                        ]
                            .map(
                              (status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _status = value;
                          });
                        },
                      );

                      final budgetField = TextFormField(
                        controller: _budget,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Presupuesto de costos',
                          prefixText: '\$ ',
                          prefixIcon: Icon(
                            Icons.attach_money,
                          ),
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            statusField,
                            const SizedBox(
                              height: 12,
                            ),
                            budgetField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: statusField,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: budgetField,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(
                          context,
                        ),
                        child: const Text(
                          'Cancelar',
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _saveProject,
                        icon: const Icon(
                          Icons.save_outlined,
                        ),
                        label: Text(
                          editing ? 'Guardar cambios' : 'Crear proyecto',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onPressed,
    bool allowClear = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white24,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      date == null
                          ? 'Sin definir'
                          : _formatDate(
                              date,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (allowClear && date != null)
            IconButton(
              tooltip: 'Quitar fecha',
              onPressed: () {
                setState(() {
                  _estimatedEndDate = null;
                });
              },
              icon: const Icon(
                Icons.close,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result == null) return;

    setState(() {
      _startDate = result;

      if (_estimatedEndDate != null &&
          _estimatedEndDate!.isBefore(_startDate)) {
        _estimatedEndDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final initial = _estimatedEndDate ??
        _startDate.add(
          const Duration(days: 30),
        );

    final result = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (result == null) return;

    setState(() {
      _estimatedEndDate = result;
    });
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final existing = widget.existing;
    final quote = widget.sourceQuote;

    final name = _name.text.trim();
    final address = _address.text.trim();
    final description = _description.text.trim();

    final budget = double.tryParse(_budget.text) ?? 0;

    if (budget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El presupuesto de costos no puede ser negativo.',
          ),
        ),
      );
      return;
    }

    try {
      Project project;

      if (quote != null) {
        // Creación exclusivamente desde cotización aprobada.
        project = await ProjectRepository.createFromApprovedQuote(
          quote: quote,
          name: name,
          startDate: _startDate,
          estimatedEndDate: _estimatedEndDate,
          description: description,
          budget: budget,
        );
      } else if (existing != null) {
        // Edición de un proyecto existente.
        project = Project(
          id: existing.id,
          clientId: existing.clientId,
          clientName: existing.clientName,
          sourceQuoteId: existing.sourceQuoteId,
          name: name,
          address: address,
          description: description,
          status: _status,
          startDate: _startDate,
          estimatedEndDate: _estimatedEndDate,
          contractedNet: existing.contractedNet,
          contractedTotal: existing.contractedTotal,
          budget: budget,
          createdAt: existing.createdAt,
        );
      } else {
        throw StateError(
          'Para crear un proyecto debes seleccionar una cotización aprobada.',
        );
      }

      if (!mounted) return;

      Navigator.pop(context, project);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'No se pudo guardar el proyecto: $error',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
