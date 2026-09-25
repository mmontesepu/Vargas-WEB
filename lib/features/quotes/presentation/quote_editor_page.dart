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

  late List<QuoteItem> items;
  late String status;

  // ============================================================
  // CLIENTES
  // ============================================================

  List<Client> clients = [];

  String? selectedClientId;

  bool loadingClients = true;

  // ============================================================
  // PROYECTOS
  // ============================================================

  List<Project> projects = [];

  String? selectedProjectId;

  bool loadingProjects = true;

  @override
  void initState() {
    super.initState();

    final q = widget.existing;

    client = TextEditingController(
      text: q?.client ?? '',
    );

    email = TextEditingController(
      text: q?.email ?? '',
    );

    address = TextEditingController(
      text: q?.address ?? '',
    );

    notes = TextEditingController(
      text: q?.notes ?? '',
    );

    payment = TextEditingController(
      text: q?.payment ?? '',
    );

    selectedClientId = q?.clientId.isNotEmpty == true ? q!.clientId : null;

    selectedProjectId = q?.projectId.isNotEmpty == true ? q!.projectId : null;

    items = q?.items
            .map(
              (item) => QuoteItem(
                item.description,
                item.unit,
                item.quantity,
                item.price,
              ),
            )
            .toList() ??
        [
          QuoteItem(
            '',
            'GL',
            1,
            0,
          ),
        ];

    status = q?.status ?? 'Borrador';

    _loadData();
  }

  Future<void> _loadData() async {
    final clientResult = await ClientRepository.getAll();

    final projectResult = await ProjectRepository.getAll();

    if (!mounted) return;

    setState(() {
      clients = clientResult;
      projects = projectResult;

      // Validamos cliente existente.
      if (selectedClientId != null &&
          !clients.any(
            (item) => item.id == selectedClientId,
          )) {
        selectedClientId = null;
      }

      // Validamos proyecto existente.
      if (selectedProjectId != null &&
          !projects.any(
            (item) => item.id == selectedProjectId,
          )) {
        selectedProjectId = null;
      }

      // Si existe proyecto pero no corresponde
      // al cliente seleccionado, lo quitamos.
      if (selectedProjectId != null && selectedClientId != null) {
        final validProject = projects.any(
          (project) =>
              project.id == selectedProjectId &&
              project.clientId == selectedClientId,
        );

        if (!validProject) {
          selectedProjectId = null;
        }
      }

      loadingClients = false;
      loadingProjects = false;
    });
  }

  @override
  void dispose() {
    client.dispose();
    email.dispose();
    address.dispose();
    notes.dispose();
    payment.dispose();

    super.dispose();
  }

  // ============================================================
  // CAMPOS
  // ============================================================

  Widget field(
    String label,
    TextEditingController controller, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final net = items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

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
        title: Text(
          widget.existing == null
              ? 'Nueva cotización'
              : 'Editar ${widget.existing!.id}',
        ),
        backgroundColor: ink,
      ),
      body: Form(
        key: form,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // =================================================
                // CLIENTE / PROYECTO
                // =================================================

                const Text(
                  'Cliente y obra',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Selecciona el cliente y, si corresponde, la obra asociada a esta cotización.',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 18),

                if (loadingClients)
                  const LinearProgressIndicator()
                else if (clients.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedClientId,
                    decoration: const InputDecoration(
                      labelText: 'Cliente registrado',
                      prefixIcon: Icon(
                        Icons.people_outline,
                      ),
                    ),
                    hint: const Text(
                      'Seleccionar cliente',
                    ),
                    items: clients
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              item.rut.isEmpty
                                  ? item.name
                                  : '${item.name} • ${item.rut}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      final selected = clients.firstWhere(
                        (item) => item.id == value,
                      );

                      setState(() {
                        selectedClientId = selected.id;

                        // Al cambiar de cliente,
                        // eliminamos cualquier proyecto
                        // seleccionado anteriormente.
                        selectedProjectId = null;

                        client.text = selected.name;

                        email.text = selected.email;

                        address.text = selected.address;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // ===============================================
                  // PROYECTO
                  // ===============================================

                  if (loadingProjects)
                    const LinearProgressIndicator()
                  else if (selectedClientId == null)
                    _informationBox(
                      icon: Icons.apartment_outlined,
                      text:
                          'Selecciona un cliente para visualizar sus proyectos.',
                    )
                  else if (availableProjects.isEmpty)
                    _informationBox(
                      icon: Icons.info_outline,
                      text:
                          'Este cliente todavía no tiene obras o proyectos registrados. La cotización puede guardarse igualmente.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'project-$selectedClientId-$selectedProjectId',
                      ),
                      initialValue: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Proyecto / Obra',
                        prefixIcon: Icon(
                          Icons.apartment_outlined,
                        ),
                      ),
                      hint: const Text(
                        'Sin proyecto asociado',
                      ),
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

                          final project = availableProjects.firstWhere(
                            (item) => item.id == value,
                          );

                          // Si la obra tiene dirección,
                          // la usamos como dirección
                          // de la cotización.
                          if (project.address.trim().isNotEmpty) {
                            address.text = project.address;
                          }
                        });
                      },
                    ),

                  const SizedBox(height: 12),
                ] else ...[
                  _informationBox(
                    icon: Icons.info_outline,
                    text:
                        'No hay clientes registrados. Puedes ingresar los datos manualmente.',
                  ),
                  const SizedBox(height: 12),
                ],

                // =================================================
                // DATOS CLIENTE
                // =================================================

                field(
                  'Nombre o empresa *',
                  client,
                  required: true,
                ),

                const SizedBox(height: 12),

                field(
                  'Correo',
                  email,
                ),

                const SizedBox(height: 12),

                field(
                  'Dirección de obra',
                  address,
                ),

                const SizedBox(height: 30),

                // =================================================
                // ITEMS
                // =================================================

                const Text(
                  'Ítems',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                ...items.asMap().entries.map(
                  (entry) {
                    final index = entry.key;

                    final item = entry.value;

                    return Card(
                      key: ValueKey(item),
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          16,
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: item.description,
                              decoration: const InputDecoration(
                                labelText: 'Descripción *',
                              ),
                              onChanged: (value) {
                                item.description = value;
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Describe el ítem';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 105,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: item.unit,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidad',
                                    ),
                                    items: [
                                      'UN',
                                      'M2',
                                      'M3',
                                      'ML',
                                      'KG',
                                      'GL',
                                    ]
                                        .map(
                                          (unit) => DropdownMenuItem<String>(
                                            value: unit,
                                            child: Text(
                                              unit,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(
                                        () {
                                          item.unit = value;
                                        },
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: TextFormField(
                                    initialValue: item.quantity.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          item.quantity = double.tryParse(
                                                value.replaceAll(
                                                  ',',
                                                  '.',
                                                ),
                                              ) ??
                                              0;
                                        },
                                      );
                                    },
                                    validator: (_) => item.quantity <= 0
                                        ? 'Debe ser > 0'
                                        : null,
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: TextFormField(
                                    initialValue: item.price.toStringAsFixed(
                                      0,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Precio unitario',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          item.price = double.tryParse(
                                                value,
                                              ) ??
                                              0;
                                        },
                                      );
                                    },
                                    validator: (_) => item.price < 0
                                        ? 'Precio inválido'
                                        : null,
                                  ),
                                ),
                                Text(
                                  _money(
                                    item.total,
                                  ),
                                  style: const TextStyle(
                                    color: gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar ítem',
                                  onPressed: items.length > 1
                                      ? () {
                                          setState(
                                            () {
                                              items.removeAt(
                                                index,
                                              );
                                            },
                                          );
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      items.add(
                        QuoteItem(
                          '',
                          'GL',
                          1,
                          0,
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Agregar ítem',
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // TOTALES
                // =================================================

                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Neto: ${_money(net)}',
                      ),
                      Text(
                        'IVA (19%): ${_money(
                          (net * .19).round(),
                        )}',
                      ),
                      Text(
                        'Total: ${_money(
                          net + (net * .19).round(),
                        )}',
                        style: const TextStyle(
                          fontSize: 26,
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // DATOS FINALES
                // =================================================

                field(
                  'Forma de pago',
                  payment,
                ),

                const SizedBox(height: 12),

                field(
                  'Observaciones',
                  notes,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                  ),
                  items: [
                    'Borrador',
                    'Enviada',
                    'Aprobada',
                    'Rechazada',
                  ]
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        status = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 28),

                FilledButton.icon(
                  onPressed: _saveQuote,
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Guardar cotización',
                  ),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION BOX
  // ============================================================

  Widget _informationBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  void _saveQuote() {
    if (!form.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();

    final id = widget.existing?.id ??
        'COT-${now.year}-${widget.nextNumber.toString().padLeft(4, '0')}';

    String projectId = '';
    String projectName = '';

    if (selectedProjectId != null && selectedProjectId!.isNotEmpty) {
      final selectedProject = projects.firstWhere(
        (project) => project.id == selectedProjectId,
      );

      projectId = selectedProject.id;

      projectName = selectedProject.name;
    }

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
      items,
    );

    Navigator.pop(
      context,
      quote,
    );
  }
}
