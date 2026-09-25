import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';
import 'project_editor_page.dart';
import 'project_detail_page.dart';

String _money(num value) => '\$${value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Project> _projects = [];

  bool _loading = true;

  String _search = '';
  String _statusFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final projects = await ProjectRepository.getAll();

    if (!mounted) return;

    setState(() {
      _projects = projects;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await ProjectRepository.saveAll(
      _projects,
    );
  }

  Future<void> _edit([
    Project? existing,
  ]) async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectEditorPage(
          existing: existing,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final index = _projects.indexWhere(
        (project) => project.id == result.id,
      );

      if (index == -1) {
        _projects.insert(0, result);
      } else {
        _projects[index] = result;
      }
    });

    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final search = _search.trim().toLowerCase();

    final filtered = _projects.where((project) {
      final matchesSearch = search.isEmpty ||
          project.name.toLowerCase().contains(search) ||
          project.clientName.toLowerCase().contains(search) ||
          project.address.toLowerCase().contains(search) ||
          project.id.toLowerCase().contains(search);

      final matchesStatus =
          _statusFilter == 'Todos' || project.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    final planning = _countStatus(
      'Planificación',
    );

    final active = _countStatus(
      'En ejecución',
    );

    final finished = _countStatus(
      'Finalizado',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1300,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //
              // HEADER
              //
              LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final compact = constraints.maxWidth < 700;

                  final title = const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Obras / Proyectos',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gestiona las obras y proyectos de Vargas SPA.',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  );

                  final button = OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                    ),
                    label: const Text(
                      'Crear desde cotización aprobada',
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(
                          height: 18,
                        ),
                        button,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Obras / Proyectos',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              'Gestiona las obras y proyectos de Vargas SPA.',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      button,
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              //
              // INDICADORES
              //
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  _summaryCard(
                    title: 'Proyectos',
                    value: '${_projects.length}',
                    icon: Icons.apartment_outlined,
                  ),
                  _summaryCard(
                    title: 'En ejecución',
                    value: '$active',
                    icon: Icons.construction_outlined,
                  ),
                  _summaryCard(
                    title: 'Planificación',
                    value: '$planning',
                    icon: Icons.calendar_month_outlined,
                  ),
                  _summaryCard(
                    title: 'Finalizados',
                    value: '$finished',
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              //
              // FILTROS
              //
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statusChip(
                    'Todos',
                    _projects.length,
                  ),
                  _statusChip(
                    'Planificación',
                    planning,
                  ),
                  _statusChip(
                    'En ejecución',
                    active,
                  ),
                  _statusChip(
                    'Pausado',
                    _countStatus(
                      'Pausado',
                    ),
                  ),
                  _statusChip(
                    'Finalizado',
                    finished,
                  ),
                  _statusChip(
                    'Cancelado',
                    _countStatus(
                      'Cancelado',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              //
              // BUSCADOR
              //
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      'Buscar por proyecto, cliente, dirección o código...',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          onPressed: _clearFilters,
                          icon: const Icon(
                            Icons.close,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              //
              // LISTADO
              //
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_projects.isEmpty)
                _emptyProjects()
              else if (filtered.isEmpty)
                _emptySearch()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: 10,
                  ),
                  itemBuilder: (_, index) {
                    return _projectCard(
                      filtered[index],
                    );
                  },
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  int _countStatus(
    String status,
  ) {
    return _projects
        .where(
          (project) => project.status == status,
        )
        .length;
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gold.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: gold,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    String status,
    int count,
  ) {
    final selected = _statusFilter == status;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        setState(() {
          _statusFilter = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? gold.withValues(
                  alpha: 0.16,
                )
              : panel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? gold
                : Colors.white.withValues(
                    alpha: 0.06,
                  ),
          ),
        ),
        child: Text(
          '$status  $count',
          style: TextStyle(
            color: selected ? gold : Colors.white70,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _financialInfo(Project project) {
    final net = project.contractedNet;
    final total = project.contractedTotal;
    final budget = project.budget;

    final margin = net - budget;
    final marginPercent = net > 0 ? (margin / net) * 100 : 0.0;

    final hasContract = project.hasSourceQuote;

    Widget amount({
      required String label,
      required double value,
      Color color = Colors.white,
      String? explanation,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
              if (explanation != null) ...[
                const SizedBox(width: 5),
                Tooltip(
                  message: explanation,
                  preferBelow: false,
                  constraints: const BoxConstraints(
                    maxWidth: 280,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _money(value),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasContract) ...[
            Text(
              'Cotización de origen: ${project.sourceQuoteId}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 30,
            runSpacing: 18,
            children: [
              SizedBox(
                width: 190,
                child: amount(
                  label: 'Neto contratado',
                  value: net,
                  color: gold,
                  explanation:
                      'Valor de venta aprobado en la cotización, sin IVA.',
                ),
              ),
              SizedBox(
                width: 190,
                child: amount(
                  label: 'Total con IVA',
                  value: total,
                  explanation: 'Monto total de venta aprobado, incluyendo IVA.',
                ),
              ),
              SizedBox(
                width: 190,
                child: amount(
                  label: 'Presupuesto estimado de costos',
                  value: budget,
                  explanation:
                      'Monto estimado para ejecutar la obra: materiales, '
                      'mano de obra, transporte y otros costos. '
                      'No corresponde a los gastos reales registrados.',
                ),
              ),
            ],
          ),
          if (hasContract) ...[
            const SizedBox(height: 16),
            const Divider(
              color: Colors.white12,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 30,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                amount(
                  label: 'Margen bruto presupuestado',
                  value: margin,
                  explanation:
                      'Diferencia entre el neto contratado y el presupuesto '
                      'estimado de costos. No representa la utilidad final.',
                  color: margin >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
                Text(
                  '${marginPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: margin >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Proyecto anterior sin cotización de origen.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openProject(Project project) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailPage(
          project: project,
        ),
      ),
    );
  }

  Widget _projectCard(
    Project project,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final compact = constraints.maxWidth < 700;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _statusBadge(
                      project.status,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  project.clientName,
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 15,
                  runSpacing: 7,
                  children: [
                    _metadata(
                      Icons.calendar_today_outlined,
                      'Inicio: ${_formatDate(project.startDate)}',
                    ),
                    if (project.estimatedEndDate != null)
                      _metadata(
                        Icons.event_available_outlined,
                        'Término: ${_formatDate(project.estimatedEndDate!)}',
                      ),
                    if (project.address.isNotEmpty)
                      _metadata(
                        Icons.location_on_outlined,
                        project.address,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _financialInfo(project),
              ],
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ver detalle de obra',
                  onPressed: () => _openProject(project),
                  icon: const Icon(
                    Icons.visibility_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar proyecto',
                  onPressed: () => _edit(project),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  information,
                  const SizedBox(
                    height: 15,
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Spacer(),
                      actions,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: information,
                ),
                const SizedBox(
                  width: 20,
                ),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    IconData icon;

    switch (status) {
      case 'En ejecución':
        icon = Icons.construction_outlined;
        break;

      case 'Finalizado':
        icon = Icons.check_circle_outline;
        break;

      case 'Pausado':
        icon = Icons.pause_circle_outline;
        break;

      case 'Cancelado':
        icon = Icons.cancel_outlined;
        break;

      default:
        icon = Icons.calendar_month_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: gold.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: gold,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadata(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _emptyProjects() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 65,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.apartment_outlined,
            size: 50,
            color: gold,
          ),
          const SizedBox(height: 15),
          const Text(
            'Aún no tienes proyectos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Las obras se generan desde cotizaciones aprobadas.',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              'Para registrar una nueva obra, crea una cotización, '
              'márcala como aprobada y utiliza la acción '
              '"Crear proyecto" desde Cotizaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 55,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 45,
            color: Colors.white38,
          ),
          const SizedBox(height: 14),
          const Text(
            'No se encontraron proyectos',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Prueba cambiando la búsqueda o el estado.',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(
              Icons.filter_alt_off_outlined,
            ),
            label: const Text(
              'Limpiar filtros',
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _search = '';
      _statusFilter = 'Todos';
    });
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
