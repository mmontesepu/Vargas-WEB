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
    try {
      final result = await QuoteRepository.getAll();

      if (!mounted) return;

      setState(() {
        quotes = result;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _message(
        'No fue posible cargar las cotizaciones: $error',
      );
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save(Quote quote) async {
    await QuoteRepository.save(quote);
  }

  Future<void> _createProject(Quote quote) async {
    if (quote.status != 'Aprobada') {
      _message(
        'Solo puedes crear proyectos desde '
        'cotizaciones aprobadas.',
      );
      return;
    }

    if (quote.clientId.trim().isEmpty) {
      _message(
        'La cotización debe tener un cliente registrado.',
      );
      return;
    }

    if (quote.projectId.trim().isNotEmpty) {
      _message(
        'Esta cotización ya está asociada a un proyecto.',
      );
      return;
    }

    try {
      final existingProject = await ProjectRepository.findBySourceQuote(
        quote.id,
      );

      if (!mounted) return;

      if (existingProject != null) {
        quote.projectId = existingProject.id;
        quote.projectName = existingProject.name;

        await _save(quote);

        if (!mounted) return;

        await _load();

        _message(
          'Se recuperó la asociación con el proyecto existente.',
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

      quote.projectId = project.id;
      quote.projectName = project.name;

      await _save(quote);

      if (!mounted) return;

      await _load();

      _message(
        'Proyecto "${project.name}" creado correctamente.',
      );
    } catch (error) {
      _message(
        'No fue posible asociar el proyecto: $error',
      );
    }
  }

  int get _nextNumber {
    final year = DateTime.now().year;

    final numbers = quotes.where((quote) {
      return quote.id.startsWith('COT-$year-');
    }).map((quote) {
      return int.tryParse(
            quote.id.split('-').last,
          ) ??
          0;
    });

    var maxNumber = 0;

    for (final number in numbers) {
      if (number > maxNumber) {
        maxNumber = number;
      }
    }

    return maxNumber + 1;
  }

  Future<void> _edit([Quote? existing]) async {
    final result = await Navigator.push<Quote>(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteEditor(
          existing: existing,
          nextNumber: _nextNumber,
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await QuoteRepository.save(result);

      if (!mounted) return;

      await _load();

      _message(
        existing == null
            ? 'Cotización creada correctamente.'
            : 'Cotización actualizada correctamente.',
      );
    } catch (error) {
      _message(
        'No fue posible guardar la cotización: $error',
      );
    }
  }

  Future<void> _generatePdf(Quote quote) async {
    try {
      await QuotePdfService.generate(quote);
    } catch (error) {
      _message(
        'No fue posible generar el PDF: $error',
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
          quote.projectName.toLowerCase().contains(search) ||
          quote.items.any(
            (item) =>
                item.description.toLowerCase().contains(search) ||
                item.activities.any(
                  (activity) => activity.toLowerCase().contains(search),
                ),
          );

      final matchesStatus =
          _statusFilter == 'Todas' || quote.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de cotizaciones',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gestiona tus propuestas y genera '
                  'documentos para tus clientes.',
                  style: TextStyle(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard(
                      'Cotizaciones',
                      '${quotes.length}',
                      Icons.description_outlined,
                    ),
                    _summaryCard(
                      'Total cotizado',
                      _money(totalQuoted),
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in [
                      'Todas',
                      'Borrador',
                      'Enviada',
                      'Aprobada',
                      'Rechazada',
                    ])
                      _statusChip(status),
                  ],
                ),
                const SizedBox(height: 24),
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
                        hintText: 'Buscar cotización...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpiar',
                                onPressed: _clearFilters,
                                icon: const Icon(
                                  Icons.close,
                                ),
                              )
                            : null,
                      ),
                    );

                    final newButton = FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add),
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
                          newButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        newButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filteredQuotes.isEmpty)
                  _emptyState()
                else ...[
                  Text(
                    '${filteredQuotes.length} '
                    '${filteredQuotes.length == 1 ? 'resultado' : 'resultados'}',
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredQuotes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _quoteCard(
                      filteredQuotes[index],
                    ),
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

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 30),
          const SizedBox(width: 14),
          Expanded(
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
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 20,
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

  Widget _statusChip(String status) {
    final count = status == 'Todas'
        ? quotes.length
        : quotes.where((quote) => quote.status == status).length;

    final selected = _statusFilter == status;

    return ChoiceChip(
      label: Text('$status ($count)'),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _statusFilter = status;
        });
      },
      selectedColor: gold.withValues(alpha: 0.20),
    );
  }

  Widget _quoteCard(Quote quote) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;

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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _statusBadge(quote.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  quote.client,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                if (quote.projectName.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Obra: ${quote.projectName}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${quote.date.day.toString().padLeft(2, '0')}/'
                  '${quote.date.month.toString().padLeft(2, '0')}/'
                  '${quote.date.year}'
                  '  •  ${quote.items.length} '
                  '${quote.items.length == 1 ? 'partida' : 'partidas'}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (quote.status == 'Aprobada' &&
                    quote.projectId.trim().isEmpty)
                  IconButton(
                    tooltip: 'Crear proyecto',
                    onPressed: () => _createProject(quote),
                    icon: const Icon(
                      Icons.add_business_outlined,
                      color: gold,
                    ),
                  ),
                if (quote.projectId.trim().isNotEmpty)
                  IconButton(
                    tooltip: 'Proyecto asociado',
                    onPressed: () {
                      _message(
                        'Proyecto asociado: '
                        '${quote.projectName}',
                      );
                    },
                    icon: const Icon(
                      Icons.apartment_outlined,
                      color: gold,
                    ),
                  ),
                IconButton(
                  tooltip: 'Generar PDF',
                  onPressed: () => _generatePdf(quote),
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
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _money(quote.total),
                          style: const TextStyle(
                            color: gold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      actions,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 16),
                Text(
                  _money(quote.total),
                  style: const TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: gold,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            color: gold,
            size: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron cotizaciones',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(
              Icons.filter_alt_off_outlined,
            ),
            label: const Text('Limpiar filtros'),
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
