import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/web_project.dart';
import '../repositories/web_project_repository.dart';

import 'web_project_gallery_page.dart';

class WebProjectsPage extends StatefulWidget {
  const WebProjectsPage({super.key});

  @override
  State<WebProjectsPage> createState() => _WebProjectsPageState();
}

class _WebProjectsPageState extends State<WebProjectsPage> {
  List<WebProject> _projects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects = await WebProjectRepository.getAll();
      if (!mounted) return;

      setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([WebProject? project]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProjectEditorDialog(project: project),
    );

    if (saved == true) await _load();
  }

  Future<void> _delete(WebProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar ficha'),
        content: Text(
          '¿Eliminar "${project.title}" del portafolio? '
          'Esta acción no elimina la obra administrativa.',
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

    if (confirmed != true) return;

    try {
      await WebProjectRepository.delete(project.id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openGallery(WebProject project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebProjectGalleryPage(
          project: project,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo completar la acción: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SizedBox(
                    width: 560,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portafolio de obras',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Administra las fichas que se mostrarán '
                          'en la página pública.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva obra'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _message(
                  Icons.error_outline,
                  'No fue posible cargar el portafolio',
                  _error!,
                )
              else if (_projects.isEmpty)
                _message(
                  Icons.photo_library_outlined,
                  'Aún no tienes obras publicitarias',
                  'Presiona Nueva obra para crear la primera ficha.',
                )
              else
                ..._projects.map(_projectTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: gold, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _projectTile(WebProject project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.image_outlined, color: gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${project.category} · '
                  '${project.location.isEmpty ? "Sin ubicación" : project.location}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  project.published ? 'Publicado' : 'Borrador',
                  style: TextStyle(
                    color: project.published ? const Color(0xFF80E7BA) : gold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar ficha',
            onPressed: () => _openEditor(project),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Administrar fotografías',
            onPressed: () => _openGallery(project),
            icon: const Icon(
              Icons.photo_library_outlined,
              color: gold,
            ),
          ),
          IconButton(
            tooltip: 'Eliminar ficha',
            onPressed: () => _delete(project),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ProjectEditorDialog extends StatefulWidget {
  final WebProject? project;

  const _ProjectEditorDialog({this.project});

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;

  late String _category;
  late bool _featured;
  bool _saving = false;
  String? _error;

  static const _categories = [
    'Construcción',
    'Remodelación',
    'Terminaciones',
    'Ampliación',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();

    final project = widget.project;

    _title = TextEditingController(text: project?.title ?? '');
    _location = TextEditingController(text: project?.location ?? '');
    _description = TextEditingController(
      text: project?.description ?? '',
    );

    _category = project?.category ?? 'Construcción';
    if (!_categories.contains(_category)) _category = 'Otros';

    _featured = project?.featured ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (widget.project == null) {
        await WebProjectRepository.create(
          title: _title.text,
          category: _category,
          location: _location.text,
          description: _description.text,
          featured: _featured,
        );
      } else {
        await WebProjectRepository.update(
          id: widget.project!.id,
          title: _title.text,
          category: _category,
          location: _location.text,
          description: _description.text,
          featured: _featured,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.project == null ? 'Nueva obra' : 'Editar obra',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Título de la obra *',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                  ),
                  items: _categories
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación general',
                    hintText: 'Ej.: San Antonio, Valparaíso',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción pública',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Destacar en la Home'),
                  subtitle: const Text(
                    'Se aplicará cuando la ficha esté publicada.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _featured,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _featured = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Guardando...' : 'Guardar borrador'),
        ),
      ],
    );
  }
}
