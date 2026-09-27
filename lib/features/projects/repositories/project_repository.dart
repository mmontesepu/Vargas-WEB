import 'package:supabase_flutter/supabase_flutter.dart';

import '../../quotes/models/quote.dart';
import '../models/project.dart';

class ProjectRepository {
  static SupabaseClient get _db => Supabase.instance.client;

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _date(dynamic value) {
    return DateTime.parse(value.toString());
  }

  static DateTime? _optionalDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static Project _fromRow(Map<String, dynamic> row) {
    return Project(
      id: row['id']?.toString() ?? '',
      clientId: row['client_id']?.toString() ?? '',
      clientName: row['client_name']?.toString() ?? '',
      sourceQuoteId: row['source_quote_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      address: row['address']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      status: row['status']?.toString() ?? 'Planificación',
      startDate: _date(row['start_date']),
      estimatedEndDate: _optionalDate(row['estimated_end_date']),
      contractedNet: _number(row['contracted_net']),
      contractedTotal: _number(row['contracted_total']),
      budget: _number(row['budget']),
      createdAt: _date(row['created_at']),
    );
  }

  static Map<String, dynamic> _toRow(Project project) {
    return {
      'id': project.id,
      'client_id': project.clientId,
      'client_name': project.clientName,
      'source_quote_id':
          project.sourceQuoteId.trim().isEmpty ? null : project.sourceQuoteId,
      'name': project.name,
      'address': project.address,
      'description': project.description,
      'status': project.status,
      'start_date': project.startDate.toIso8601String(),
      'estimated_end_date': project.estimatedEndDate?.toIso8601String(),
      'contracted_net': project.contractedNet,
      'contracted_total': project.contractedTotal,
      'budget': project.budget,
      'created_at': project.createdAt.toIso8601String(),
    };
  }

  static Future<List<Project>> getAll() async {
    final rows = await _db
        .from('projects')
        .select()
        .order('created_at', ascending: false);

    return rows.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList();
  }

  static Future<Project?> findBySourceQuote(String quoteId) async {
    if (quoteId.trim().isEmpty) return null;

    final row = await _db
        .from('projects')
        .select()
        .eq('source_quote_id', quoteId)
        .maybeSingle();

    if (row == null) return null;

    return _fromRow(Map<String, dynamic>.from(row));
  }

  static Future<void> save(Project project) async {
    if (project.id.trim().isEmpty) {
      throw StateError('El proyecto no tiene identificador.');
    }

    if (project.clientId.trim().isEmpty) {
      throw StateError('El proyecto debe tener un cliente registrado.');
    }

    if (project.name.trim().isEmpty) {
      throw StateError('Ingresa el nombre del proyecto.');
    }

    if (!project.budget.isFinite || project.budget < 0) {
      throw StateError('El presupuesto de costos no es válido.');
    }

    if (project.estimatedEndDate != null &&
        project.estimatedEndDate!.isBefore(project.startDate)) {
      throw StateError(
        'La fecha de término no puede ser anterior al inicio.',
      );
    }

    // Solo actualiza un proyecto existente.
    // La creación desde cotización utiliza la función transaccional.
    final existing = await _db
        .from('projects')
        .select('id')
        .eq('id', project.id)
        .maybeSingle();

    if (existing == null) {
      throw StateError(
        'El proyecto no existe. Debes crearlo desde una cotización aprobada.',
      );
    }

    final data = _toRow(project)
      ..remove('id')
      ..remove('client_id')
      ..remove('client_name')
      ..remove('source_quote_id')
      ..remove('contracted_net')
      ..remove('contracted_total')
      ..remove('created_at');

    await _db.from('projects').update(data).eq('id', project.id);
  }

  // Compatibilidad temporal con llamadas antiguas.
  // No crea proyectos nuevos ni elimina registros.
  static Future<void> saveAll(List<Project> projects) async {
    for (final project in projects) {
      await save(project);
    }
  }

  static Future<Project> createFromApprovedQuote({
    required Quote quote,
    required String name,
    required DateTime startDate,
    DateTime? estimatedEndDate,
    String description = '',
    double budget = 0,
  }) async {
    if (quote.status != 'Aprobada') {
      throw StateError(
        'Solo una cotización aprobada puede generar un proyecto.',
      );
    }

    if (quote.id.trim().isEmpty) {
      throw StateError('La cotización no tiene identificador.');
    }

    if (quote.clientId.trim().isEmpty) {
      throw StateError(
        'La cotización debe estar asociada a un cliente registrado.',
      );
    }

    if (quote.projectId.trim().isNotEmpty) {
      throw StateError(
        'Esta cotización ya está asociada a una obra.',
      );
    }

    if (name.trim().isEmpty) {
      throw StateError('Ingresa el nombre del proyecto.');
    }

    if (!budget.isFinite || budget < 0) {
      throw StateError(
        'El presupuesto de costos no puede ser negativo.',
      );
    }

    if (estimatedEndDate != null && estimatedEndDate.isBefore(startDate)) {
      throw StateError(
        'La fecha de término no puede ser anterior al inicio.',
      );
    }

    final existing = await findBySourceQuote(quote.id);

    if (existing != null) {
      throw StateError(
        'Esta cotización ya generó un proyecto.',
      );
    }

    final now = DateTime.now();

    final project = Project(
      id: 'PRY-${now.microsecondsSinceEpoch}',
      clientId: quote.clientId,
      clientName: quote.client,
      sourceQuoteId: quote.id,
      name: name.trim(),
      address: quote.address.trim(),
      description: description.trim(),
      status: 'Planificación',
      startDate: startDate,
      estimatedEndDate: estimatedEndDate,
      contractedNet: quote.net,
      contractedTotal: quote.total,
      budget: budget,
      createdAt: now,
    );

    await _db.rpc(
      'create_project_from_quote',
      params: {
        'p_project': _toRow(project),
      },
    );

    return project;
  }
}
