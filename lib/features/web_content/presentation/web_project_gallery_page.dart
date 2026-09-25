import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/web_project.dart';
import '../models/web_project_image.dart';
import '../repositories/web_project_image_repository.dart';

class WebProjectGalleryPage extends StatefulWidget {
  final WebProject project;

  const WebProjectGalleryPage({
    super.key,
    required this.project,
  });

  @override
  State<WebProjectGalleryPage> createState() => _WebProjectGalleryPageState();
}

class _WebProjectGalleryPageState extends State<WebProjectGalleryPage> {
  List<WebProjectImage> _images = [];
  Map<String, String> _urls = {};

  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _coverPath;

  @override
  void initState() {
    super.initState();
    _coverPath = widget.project.coverPath;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
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
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _upload() async {
    if (_uploading) return;

    try {
      // API de file_picker 13.x:
      // pickFiles devuelve directamente List<PlatformFile>.
      final files = await picker.FilePicker.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (files.isEmpty) return;

      setState(() => _uploading = true);

      var uploaded = 0;

      for (final file in files) {
        // En file_picker 13.x los bytes se leen mediante
        // readAsBytes(), no mediante file.bytes.
        final bytes = await file.readAsBytes();

        if (bytes.isEmpty) {
          throw StateError(
            'No fue posible leer "${file.name}".',
          );
        }

        if (bytes.length > 10 * 1024 * 1024) {
          throw StateError(
            '"${file.name}" supera el límite de 10 MB.',
          );
        }

        final extension = file.extension ?? '';

        final image = await WebProjectImageRepository.upload(
          projectId: widget.project.id,
          bytes: bytes,
          extension: extension,
        );

        // La primera fotografía queda como portada.
        if (_coverPath == null) {
          await WebProjectImageRepository.setCover(
            projectId: widget.project.id,
            storagePath: image.storagePath,
          );

          _coverPath = image.storagePath;
        }

        uploaded++;
      }

      if (!mounted) return;

      _showMessage(
        uploaded == 1
            ? 'Fotografía cargada correctamente.'
            : '$uploaded fotografías cargadas correctamente.',
      );

      await _load();
    } catch (error) {
      _showMessage('Error al cargar fotografías: $error');
      await _load();
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _setCover(WebProjectImage image) async {
    try {
      await WebProjectImageRepository.setCover(
        projectId: widget.project.id,
        storagePath: image.storagePath,
      );

      if (!mounted) return;

      setState(() => _coverPath = image.storagePath);
      _showMessage('Portada actualizada.');
    } catch (error) {
      _showMessage('No se pudo cambiar la portada: $error');
    }
  }

  Future<void> _delete(WebProjectImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar fotografía'),
        content: const Text(
          '¿Deseas eliminar esta fotografía del portafolio?',
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
      await WebProjectImageRepository.delete(
        image: image,
        currentCoverPath: _coverPath,
      );

      await _load();
      _showMessage('Fotografía eliminada.');
    } catch (error) {
      _showMessage('No se pudo eliminar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        title: Text(widget.project.title),
        backgroundColor: ink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
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
                            'Galería de fotografías',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Selecciona las imágenes de la obra '
                            'y define su portada.',
                            style: TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _uploading ? null : _upload,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                      ),
                      label: Text(
                        _uploading ? 'Subiendo...' : 'Agregar fotografías',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'JPG, PNG o WebP · Máximo 10 MB por imagen.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (_uploading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  )
                else if (_images.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white12,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: gold,
                          size: 38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Esta obra todavía no tiene fotografías.',
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Utiliza Agregar fotografías para '
                          'cargar las primeras imágenes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 850
                          ? 3
                          : width >= 520
                              ? 2
                              : 1;

                      final itemWidth = (width - (columns - 1) * 14) / columns;

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final image in _images)
                            SizedBox(
                              width: itemWidth,
                              child: _imageCard(image),
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

  Widget _imageCard(WebProjectImage image) {
    final isCover = image.storagePath == _coverPath;
    final url = _urls[image.id];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCover ? gold : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: url == null
                ? const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: isCover
                      ? const Text(
                          '★ Portada',
                          style: TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : TextButton(
                          onPressed: () => _setCover(image),
                          child: const Text(
                            'Elegir portada',
                          ),
                        ),
                ),
                IconButton(
                  tooltip: isCover
                      ? 'Cambia la portada antes de eliminar'
                      : 'Eliminar fotografía',
                  onPressed: isCover ? null : () => _delete(image),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
