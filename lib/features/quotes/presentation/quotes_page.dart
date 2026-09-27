import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/quote.dart';
import '../repositories/quote_repository.dart';
import '../services/quote_pdf_service.dart';
import 'quote_editor_page.dart';

import '../../projects/models/project.dart';
import '../../projects/repositories/project_repository.dart';
import '../../projects/presentation/project_editor_page.dart';

String _money(num value) => '\$${value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}';

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  List<Quote> quotes = [];

  bool loading = true;

  String _search = '';
  String _statusFilter = 'Todas';

  final TextEditingController _searchController = TextEditingController();

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
    final result = await QuoteRepository.getAll();

    if (!mounted) return;

    setState(() {
      quotes = result;
      loading = false;
    });
  }

  Future<void> _save(Quote quote) async {
    await QuoteRepository.save(quote);
  }

  Future<void> _createProject(Quote quote) async {
    if (quote.status != 'Aprobada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo puedes crear proyectos desde cotizaciones aprobadas.',
          ),
        ),
      );
      return;
    }

    if (quote.clientId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La cotización debe tener un cliente registrado.',
          ),
        ),
      );
      return;
    }

    if (quote.projectId.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta cotización ya está asociada a un proyecto.',
          ),
        ),
      );
      return;
    }

    final existingProject = await ProjectRepository.findBySourceQuote(quote.id);

    if (!mounted) return;

    if (existingProject != null) {
      // Recuperación de una relación que no quedó reflejada
      // en la cotización, evitando generar una obra duplicada.
      quote.projectId = existingProject.id;
      quote.projectName = existingProject.name;

      await _save(quote);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La cotización ya tenía un proyecto. Se recuperó su asociación.',
          ),
        ),
      );
      return;
    }

    final project = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectEditorPage(
          sourceQuote: quote,
        ),
      ),
    );

    if (!mounted || project == null) return;

    // El formulario ya guardó el proyecto mediante
    // ProjectRepository.createFromApprovedQuote().
    // Aquí solamente vinculamos la cotización.
    quote.projectId = project.id;
    quote.projectName = project.name;

    await _save(quote);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Proyecto "${project.name}" creado correctamente.',
        ),
      ),
    );
  }

  Future<void> _edit([Quote? existing]) async {
    final result = await Navigator.push<Quote>(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteEditor(
          existing: existing,
          nextNumber: quotes.length + 1,
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await QuoteRepository.save(result);

      if (!mounted) return;

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Cotización creada correctamente.'
                : 'Cotización actualizada correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible guardar la cotización: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = _search.trim().toLowerCase();

    final filteredQuotes = quotes.where((quote) {
      final matchesSearch = search.isEmpty ||
          quote.id.toLowerCase().contains(search) ||
          quote.client.toLowerCase().contains(search) ||
          quote.email.toLowerCase().contains(search) ||
          quote.address.toLowerCase().contains(search) ||
          quote.projectName.toLowerCase().contains(search);

      final matchesStatus =
          _statusFilter == 'Todas' || quote.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    final draftCount = quotes
        .where(
          (quote) => quote.status == 'Borrador',
        )
        .length;

    final sentCount = quotes
        .where(
          (quote) => quote.status == 'Enviada',
        )
        .length;

    final approvedCount = quotes
        .where(
          (quote) => quote.status == 'Aprobada',
        )
        .length;

    final rejectedCount = quotes
        .where(
          (quote) => quote.status == 'Rechazada',
        )
        .length;

    final totalQuoted = quotes.fold<double>(
      0,
      (sum, quote) => sum + quote.total,
    );

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1150,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de cotizaciones',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Gestiona tus propuestas y genera documentos para tus clientes.',
                  style: TextStyle(
                    color: Colors.white60,
                  ),
                ),

                const SizedBox(height: 28),

                //
                // RESUMEN
                //
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    _summaryCard(
                      title: 'Cotizaciones',
                      value: '${quotes.length}',
                      icon: Icons.description_outlined,
                    ),
                    _summaryCard(
                      title: 'Total cotizado',
                      value: _money(totalQuoted),
                      icon: Icons.attach_money,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                //
                // FILTROS DE ESTADO
                //
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statusChip(
                      label: 'Todas',
                      count: quotes.length,
                    ),
                    _statusChip(
                      label: 'Borrador',
                      count: draftCount,
                    ),
                    _statusChip(
                      label: 'Enviada',
                      count: sentCount,
                    ),
                    _statusChip(
                      label: 'Aprobada',
                      count: approvedCount,
                    ),
                    _statusChip(
                      label: 'Rechazada',
                      count: rejectedCount,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                //
                // BUSCADOR + NUEVA COTIZACIÓN
                //
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 700;

                    final searchField = TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Buscar por cotización, cliente, proyecto, correo o dirección...',
                        prefixIcon: const Icon(
                          Icons.search,
                        ),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  _searchController.clear();

                                  setState(() {
                                    _search = '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                ),
                              )
                            : null,
                      ),
                    );

                    final newQuoteButton = FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Nueva cotización',
                      ),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          newQuoteButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: searchField,
                        ),
                        const SizedBox(width: 14),
                        newQuoteButton,
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                //
                // RESULTADOS
                //
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 60,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (quotes.isEmpty)
                  _emptyQuotes()
                else if (filteredQuotes.isEmpty)
                  _emptySearch()
                else ...[
                  Row(
                    children: [
                      Text(
                        '${filteredQuotes.length} '
                        '${filteredQuotes.length == 1 ? 'resultado' : 'resultados'}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_statusFilter != 'Todas' || _search.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(
                            Icons.filter_alt_off_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Limpiar filtros',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredQuotes.length,
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 10,
                    ),
                    itemBuilder: (_, index) {
                      final quote = filteredQuotes[index];

                      return _quoteCard(quote);
                    },
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //
  // TARJETA RESUMEN
  //
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: gold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //
  // CHIP DE ESTADO
  //
  Widget _statusChip({
    required String label,
    required int count,
  }) {
    final selected = _statusFilter == label;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        setState(() {
          _statusFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? gold : Colors.white70,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? gold.withValues(
                        alpha: 0.18,
                      )
                    : Colors.white.withValues(
                        alpha: 0.06,
                      ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? gold : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
  // TARJETA DE COTIZACIÓN
  //
  Widget _quoteCard(Quote quote) {
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
                      quote.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _statusBadge(
                      quote.status,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  quote.client,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (quote.projectName.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _metadata(
                    Icons.apartment_outlined,
                    'Obra: ${quote.projectName}',
                  ),
                ],
                const SizedBox(height: 5),
                Wrap(
                  spacing: 14,
                  runSpacing: 5,
                  children: [
                    _metadata(
                      Icons.calendar_today_outlined,
                      '${quote.date.day.toString().padLeft(2, '0')}/'
                      '${quote.date.month.toString().padLeft(2, '0')}/'
                      '${quote.date.year}',
                    ),
                    if (quote.email.isNotEmpty)
                      _metadata(
                        Icons.email_outlined,
                        quote.email,
                      ),
                  ],
                ),
              ],
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _money(quote.total),
                  style: const TextStyle(
                    color: gold,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (quote.status == 'Aprobada' &&
                    quote.projectId.trim().isEmpty)
                  IconButton(
                    tooltip: 'Crear proyecto desde esta cotización',
                    onPressed: () => _createProject(quote),
                    icon: const Icon(
                      Icons.add_business_outlined,
                      color: gold,
                    ),
                  ),
                if (quote.projectId.trim().isNotEmpty)
                  IconButton(
                    tooltip: 'Proyecto asociado: ${quote.projectName}',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Proyecto asociado: ${quote.projectName}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.apartment_outlined,
                      color: gold,
                    ),
                  ),
                IconButton(
                  tooltip: 'Generar PDF',
                  onPressed: () => QuotePdfService.generate(quote),
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar cotización',
                  onPressed: () => _edit(quote),
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
                    height: 16,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 5,
                  ),
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

  //
  // BADGE DE ESTADO
  //
  Widget _statusBadge(
    String status,
  ) {
    IconData icon;

    switch (status) {
      case 'Aprobada':
        icon = Icons.check_circle_outline;
        break;

      case 'Rechazada':
        icon = Icons.cancel_outlined;
        break;

      case 'Enviada':
        icon = Icons.send_outlined;
        break;

      default:
        icon = Icons.edit_note_outlined;
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
    String value,
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
          value,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  //
  // SIN COTIZACIONES
  //
  Widget _emptyQuotes() {
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
            Icons.description_outlined,
            size: 50,
            color: gold,
          ),
          const SizedBox(height: 15),
          const Text(
            'Aún no tienes cotizaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Crea tu primera cotización para comenzar.',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text(
              'Nueva cotización',
            ),
          ),
        ],
      ),
    );
  }

  //
  // SIN RESULTADOS
  //
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
            'No se encontraron cotizaciones',
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
      _statusFilter = 'Todas';
    });
  }
}
