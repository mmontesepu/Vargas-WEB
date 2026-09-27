import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../models/web_project.dart';
import '../models/web_project_image.dart';
import '../repositories/web_project_image_repository.dart';

class PublicProjectDetailPage extends StatefulWidget {
  final WebProject project;

  const PublicProjectDetailPage({
    super.key,
    required this.project,
  });

  @override
  State<PublicProjectDetailPage> createState() =>
      _PublicProjectDetailPageState();
}

class _PublicProjectDetailPageState extends State<PublicProjectDetailPage> {
  List<WebProjectImage> _images = [];
  Map<String, String> _urls = {};

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
      // Verificar nuevamente que la obra siga publicada.
      final published =
          await WebProjectRepositoryPublic.isPublished(widget.project.id);

      if (!published) {
        throw StateError('Esta obra ya no está disponible públicamente.');
      }

      final images = await WebProjectImageRepository.getByProject(
        widget.project.id,
      );

      final urls = <String, String>{};

      for (final image in images) {
        urls[image.id] = await WebProjectImageRepository.signedUrl(
          image.storagePath,
        );
      }

      if (!mounted) return;

      setState(() {
        _images = images;
        _urls = urls;
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

  void _openPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ink,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filledTonal(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        title: const Text('Portafolio de obras'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VARGAS SPA · PROYECTOS',
                  style: TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(project.category)),
                    if (project.location.trim().isNotEmpty)
                      Chip(
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                        ),
                        label: Text(project.location),
                      ),
                  ],
                ),
                if (project.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    project.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Galería fotográfica',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  )
                else if (_images.isEmpty)
                  const Text(
                    'No hay fotografías disponibles.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 850
                          ? 3
                          : constraints.maxWidth >= 520
                              ? 2
                              : 1;

                      const gap = 14.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final image in _images)
                            SizedBox(
                              width: width,
                              child: AspectRatio(
                                aspectRatio: 16 / 10,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Material(
                                    color: panel,
                                    child: InkWell(
                                      onTap: _urls[image.id] == null
                                          ? null
                                          : () => _openPhoto(
                                                _urls[image.id]!,
                                              ),
                                      child: _urls[image.id] == null
                                          ? const Icon(
                                              Icons.image_outlined,
                                              color: gold,
                                            )
                                          : Image.network(
                                              _urls[image.id]!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) =>
                                                  const Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Consulta de seguridad adicional al abrir el detalle.
class WebProjectRepositoryPublic {
  static Future<bool> isPublished(String id) async {
    final rows = await Supabase.instance.client
        .from('web_projects')
        .select('id')
        .eq('id', id)
        .eq('published', true)
        .limit(1);

    return rows.isNotEmpty;
  }
}
