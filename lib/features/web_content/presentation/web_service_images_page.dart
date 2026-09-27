import 'package:file_picker/file_picker.dart' as picker;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../repositories/web_service_image_repository.dart';

class WebServiceImagesPage extends StatefulWidget {
  const WebServiceImagesPage({super.key});

  @override
  State<WebServiceImagesPage> createState() => _WebServiceImagesPageState();
}

class _WebServiceImagesPageState extends State<WebServiceImagesPage> {
  static const _services = <String, String>{
    'construction': 'Construcción',
    'renovation': 'Remodelaciones',
    'finishes': 'Terminaciones',
  };

  Map<String, String?> _paths = {};
  Map<String, String> _urls = {};

  bool _loading = true;
  String? _savingKey;
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
      final paths = await WebServiceImageRepository.getAll();
      final urls = <String, String>{};

      for (final entry in paths.entries) {
        final path = entry.value;

        if (path == null || path.trim().isEmpty) continue;

        urls[entry.key] = await WebServiceImageRepository.signedUrl(path);
      }

      if (!mounted) return;

      setState(() {
        _paths = paths;
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

  Future<void> _changeImage(String serviceKey) async {
    if (_savingKey != null) return;

    try {
      final files = await picker.FilePicker.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw StateError('No fue posible leer la fotografía.');
      }

      if (!mounted) return;

      setState(() => _savingKey = serviceKey);

      await WebServiceImageRepository.replace(
        serviceKey: serviceKey,
        bytes: bytes,
        extension: file.extension ?? '',
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fotografía de ${_services[serviceKey]} actualizada.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible guardar la imagen: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingKey = null);
      }
    }
  }

  Widget _serviceCard(String key, String title) {
    final url = _urls[key];
    final busy = _savingKey == key;

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: url == null
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: gold,
                      size: 52,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: gold,
                        size: 40,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _paths[key] == null
                      ? 'Usando imagen referencial en la Home.'
                      : 'Fotografía personalizada configurada.',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed:
                      _savingKey != null ? null : () => _changeImage(key),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: Text(
                    busy ? 'Guardando...' : 'Cambiar fotografía',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              const Text(
                'Imágenes de servicios',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personaliza las fotografías de Construcción, '
                'Remodelaciones y Terminaciones.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 8),
              const Text(
                'Formatos: JPG, PNG o WebP · Máximo 10 MB.',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 26),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final entry in _services.entries)
                      _serviceCard(entry.key, entry.value),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
