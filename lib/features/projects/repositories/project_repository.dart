import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../quotes/models/quote.dart';
import '../models/project.dart';

class ProjectRepository {
  static const String _storageKey = 'projects';

  static Future<List<Project>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final raw = prefs.getString(_storageKey) ?? '[]';

      return (jsonDecode(raw) as List)
          .map(
            (item) => Project.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(
    List<Project> projects,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(
        projects.map((project) => project.toJson()).toList(),
      ),
    );

    if (!saved) {
      throw StateError('No se pudieron guardar los proyectos.');
    }
  }

  static Future<Project?> findBySourceQuote(
    String quoteId,
  ) async {
    final projects = await getAll();

    for (final project in projects) {
      if (project.sourceQuoteId == quoteId) {
        return project;
      }
    }

    return null;
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

    if (budget < 0) {
      throw StateError(
        'El presupuesto de costos no puede ser negativo.',
      );
    }

    if (estimatedEndDate != null && estimatedEndDate.isBefore(startDate)) {
      throw StateError(
        'La fecha de término no puede ser anterior al inicio.',
      );
    }

    final projects = await getAll();

    final alreadyExists = projects.any(
      (project) => project.sourceQuoteId == quote.id,
    );

    if (alreadyExists) {
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

    projects.insert(0, project);

    await saveAll(projects);

    return project;
  }
}
