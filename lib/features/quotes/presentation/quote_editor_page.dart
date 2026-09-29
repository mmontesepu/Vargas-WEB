import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';

import '../../clients/models/client.dart';
import '../../clients/repositories/client_repository.dart';

import '../../projects/models/project.dart';
import '../../projects/repositories/project_repository.dart';

import '../models/quote.dart';
import '../models/quote_item.dart';

String _money(num value) => '\$${value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}';

class QuoteEditor extends StatefulWidget {
  final Quote? existing;
  final int nextNumber;

  const QuoteEditor({
    super.key,
    this.existing,
    required this.nextNumber,
  });

  @override
  State<QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<QuoteEditor> {
  final form = GlobalKey<FormState>();

  late final TextEditingController client;
  late final TextEditingController email;
  late final TextEditingController address;
  late final TextEditingController notes;
  late final TextEditingController payment;
  late final TextEditingController netAmount;

  late List<QuoteItem> items;
  late String status;

  List<Client> clients = [];
  List<Project> projects = [];

  String? selectedClientId;
  String? selectedProjectId;

  bool loadingClients = true;
  bool loadingProjects = true;

  @override
  void initState() {
    super.initState();

    final q = widget.existing;

    client = TextEditingController(text: q?.client ?? '');
    email = TextEditingController(text: q?.email ?? '');
    address = TextEditingController(text: q?.address ?? '');
    notes = TextEditingController(text: q?.notes ?? '');
    payment = TextEditingController(text: q?.payment ?? '');

    netAmount = TextEditingController(
      text: q == null ? '' : _digits(q.net),
    );

    selectedClientId = q?.clientId.isNotEmpty == true ? q!.clientId : null;

    selectedProjectId = q?.projectId.isNotEmpty == true ? q!.projectId : null;

    items = q == null
        ? [QuoteItem.partida()]
        : q.items.map((item) => item.copy()).toList();

    if (items.isEmpty) {
      items.add(QuoteItem.partida());
    }

    status = q?.status ?? 'Borrador';

    _loadData();
  }

  String _digits(num value) {
    return value.round().toString();
  }

  double get _net {
    return double.tryParse(
          netAmount.text.replaceAll('.', '').trim(),
        ) ??
        0;
  }

  double get _vat => (_net * 0.19).roundToDouble();

  double get _total => _net + _vat;

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        ClientRepository.getAll(),
        ProjectRepository.getAll(),
      ]);

      if (!mounted) return;

      setState(() {
        clients = results[0] as List<Client>;
        projects = results[1] as List<Project>;

        if (selectedClientId != null &&
            !clients.any((c) => c.id == selectedClientId)) {
          selectedClientId = null;
        }

        if (selectedProjectId != null &&
            !projects.any((p) => p.id == selectedProjectId)) {
          selectedProjectId = null;
        }

        if (selectedClientId != null &&
            selectedProjectId != null &&
            !projects.any(
              (p) =>
                  p.id == selectedProjectId && p.clientId == selectedClientId,
            )) {
          selectedProjectId = null;
        }

        loadingClients = false;
        loadingProjects = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingClients = false;
        loadingProjects = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible cargar clientes y proyectos: $error',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    client.dispose();
    email.dispose();
    address.dispose();
    notes.dispose();
    payment.dispose();
    netAmount.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            }
          : null,
    );
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _informationBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _addPartida() {
    setState(() {
      items.add(QuoteItem.partida());
    });
  }

  void _removePartida(int index) {
    if (items.length <= 1) return;

    setState(() {
      items.removeAt(index);
    });
  }

  void _addActivity(QuoteItem item) {
    setState(() {
      item.activities.add('');
    });
  }

  void _removeActivity(QuoteItem item, int index) {
    setState(() {
      item.activities.removeAt(index);
    });
  }

  Widget _partidaCard(QuoteItem item, int index) {
    return Card(
      key: ObjectKey(item),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Partida ${index + 1}',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar partida',
                  onPressed:
                      items.length > 1 ? () => _removePartida(index) : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('partida-${identityHashCode(item)}'),
              initialValue: item.description,
              decoration: const InputDecoration(
                labelText: 'Nombre de la partida *',
                hintText: 'Ej.: Pintura',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              onChanged: (value) {
                item.description = value;
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre de la partida';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Trabajos incluidos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Describe las actividades que contempla esta partida. '
              'No se asignan precios individuales.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            ...item.activities.asMap().entries.map((entry) {
              final activityIndex = entry.key;
              final activity = entry.value;

              return Padding(
                key: ValueKey(
                  'activity-${identityHashCode(item)}-$activityIndex',
                ),
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: activity,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Actividad ${activityIndex + 1}',
                          hintText: 'Ej.: Lijado de paredes',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (value) {
                          item.activities[activityIndex] = value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Describe la actividad';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Eliminar actividad',
                      onPressed: () => _removeActivity(item, activityIndex),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => _addActivity(item),
              icon: const Icon(Icons.add),
              label: const Text('Agregar actividad'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableProjects = selectedClientId == null
        ? <Project>[]
        : projects
            .where(
              (project) => project.clientId == selectedClientId,
            )
            .toList();

    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        title: Text(
          widget.existing == null
              ? 'Nueva cotización'
              : 'Editar ${widget.existing!.id}',
        ),
      ),
      body: Form(
        key: form,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;

                return ListView(
                  padding: EdgeInsets.all(compact ? 14 : 24),
                  children: [
                    _heading(
                      'Cliente y obra',
                      'Selecciona el cliente y, si corresponde, '
                          'la obra asociada.',
                    ),
                    const SizedBox(height: 18),
                    if (loadingClients)
                      const LinearProgressIndicator()
                    else if (clients.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'client-$selectedClientId',
                        ),
                        initialValue: selectedClientId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cliente registrado',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        hint: const Text('Seleccionar cliente'),
                        items: clients.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              item.rut.isEmpty
                                  ? item.name
                                  : '${item.name} • ${item.rut}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          final selected = clients.firstWhere(
                            (item) => item.id == value,
                          );

                          setState(() {
                            selectedClientId = selected.id;
                            selectedProjectId = null;
                            client.text = selected.name;
                            email.text = selected.email;
                            address.text = selected.address;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (loadingProjects)
                        const LinearProgressIndicator()
                      else if (selectedClientId == null)
                        _informationBox(
                          'Selecciona un cliente para visualizar '
                          'sus proyectos.',
                        )
                      else if (availableProjects.isEmpty)
                        _informationBox(
                          'Este cliente todavía no tiene obras '
                          'registradas. Puedes guardar la cotización '
                          'sin asociarla a un proyecto.',
                        )
                      else
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'project-$selectedClientId-$selectedProjectId',
                          ),
                          initialValue: selectedProjectId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Proyecto / Obra',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                          hint: const Text('Sin proyecto asociado'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text(
                                'Sin proyecto asociado',
                              ),
                            ),
                            ...availableProjects.map(
                              (project) => DropdownMenuItem<String>(
                                value: project.id,
                                child: Text(
                                  '${project.name} • ${project.status}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == null || value.isEmpty) {
                                selectedProjectId = null;
                                return;
                              }

                              selectedProjectId = value;

                              final selected = availableProjects.firstWhere(
                                (p) => p.id == value,
                              );

                              if (selected.address.trim().isNotEmpty) {
                                address.text = selected.address;
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                    ] else ...[
                      _informationBox(
                        'No hay clientes registrados. Puedes '
                        'ingresar los datos manualmente.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    _field(
                      'Nombre o empresa *',
                      client,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _field('Correo', email),
                    const SizedBox(height: 12),
                    _field('Dirección de obra', address),
                    const SizedBox(height: 30),
                    _heading(
                      'Partidas y trabajos',
                      'Organiza los trabajos por partida. '
                          'Cada partida puede contener varias '
                          'descripciones, sin precios individuales.',
                    ),
                    const SizedBox(height: 16),
                    ...items.asMap().entries.map(
                          (entry) => _partidaCard(
                            entry.value,
                            entry.key,
                          ),
                        ),
                    OutlinedButton.icon(
                      onPressed: _addPartida,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar partida'),
                    ),
                    const SizedBox(height: 30),
                    _heading(
                      'Presupuesto general',
                      'Ingresa un único monto neto para toda '
                          'la cotización.',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: netAmount,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Monto neto general *',
                                prefixText: '\$ ',
                                hintText: '2500000',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa el monto neto';
                                }

                                final amount = double.tryParse(
                                  value,
                                );

                                if (amount == null || amount < 0) {
                                  return 'Monto inválido';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            _totalRow(
                              'Neto',
                              _money(_net),
                            ),
                            const SizedBox(height: 9),
                            _totalRow(
                              'IVA (19 %)',
                              _money(_vat),
                            ),
                            const Divider(height: 28),
                            _totalRow(
                              'TOTAL',
                              _money(_total),
                              highlighted: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _heading(
                      'Condiciones de la cotización',
                      'Forma de pago, observaciones y estado.',
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Forma de pago',
                      payment,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Observaciones',
                      notes,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                      ),
                      items: [
                        'Borrador',
                        'Enviada',
                        'Aprobada',
                        'Rechazada',
                      ].map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _saveQuote,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar cotización'),
                    ),
                    const SizedBox(height: 36),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool highlighted = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: highlighted ? 18 : 14,
              fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlighted ? gold : Colors.white,
            fontSize: highlighted ? 23 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _saveQuote() {
    if (!form.currentState!.validate()) {
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una partida.'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final id = widget.existing?.id ??
        'COT-${now.year}-${widget.nextNumber.toString().padLeft(4, '0')}';

    String projectId = '';
    String projectName = '';

    if (selectedProjectId != null && selectedProjectId!.isNotEmpty) {
      final selected = projects.firstWhere(
        (project) => project.id == selectedProjectId,
      );

      projectId = selected.id;
      projectName = selected.name;
    }

    final cleanItems = items.map((item) {
      return QuoteItem.partida(
        description: item.description.trim(),
        activities: item.activities
            .map((activity) => activity.trim())
            .where((activity) => activity.isNotEmpty)
            .toList(),
      );
    }).toList();

    final quote = Quote(
      id,
      selectedClientId ?? '',
      client.text.trim(),
      projectId,
      projectName,
      email.text.trim(),
      address.text.trim(),
      notes.text.trim(),
      payment.text.trim(),
      status,
      widget.existing?.date ?? now,
      cleanItems,
      netAmount: _net,
    );

    Navigator.pop(context, quote);
  }
}
