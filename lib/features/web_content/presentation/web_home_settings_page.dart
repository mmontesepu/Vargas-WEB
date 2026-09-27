import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../repositories/web_site_settings_repository.dart';

class WebHomeSettingsPage extends StatefulWidget {
  const WebHomeSettingsPage({super.key});

  @override
  State<WebHomeSettingsPage> createState() => _WebHomeSettingsPageState();
}

class _WebHomeSettingsPageState extends State<WebHomeSettingsPage> {
  String? _heroPath;
  String? _heroUrl;
  String? _error;

  bool _loading = true;
  bool _saving = false;

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
      final path = await WebSiteSettingsRepository.getHeroPath();

      String? url;

      if (path != null && path.trim().isNotEmpty) {
        url = await WebSiteSettingsRepository.signedUrl(path);
      }

      if (!mounted) return;

      setState(() {
        _heroPath = path;
        _heroUrl = url;
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

  Future<void> _changeHero() async {
    if (_saving) return;

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

      setState(() => _saving = true);

      await WebSiteSettingsRepository.replaceHero(
        bytes: bytes,
        extension: file.extension ?? '',
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fotografía principal actualizada correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible guardar la fotografía: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Página principal',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administra el contenido destacado de la página '
                'pública de Vargas SPA.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.wallpaper_outlined,
                          color: gold,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Fotografía principal (Hero)',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Esta fotografía aparece en la parte superior '
                      'del sitio, detrás del título principal.',
                      style: TextStyle(
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 7,
                        child: _buildPreview(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _heroPath == null
                          ? 'Actualmente se utiliza la fotografía '
                              'referencial de la Home.'
                          : 'Fotografía personalizada configurada.',
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: (_loading || _saving) ? null : _changeHero,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: Text(
                        _saving
                            ? 'Guardando fotografía...'
                            : 'Cambiar fotografía principal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Formatos: JPG, PNG o WebP · Máximo 10 MB.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_loading) {
      return const ColoredBox(
        color: Color(0xFF27292B),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: const Color(0xFF27292B),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: gold,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No fue posible cargar la configuración.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_heroUrl == null) {
      return const ColoredBox(
        color: Color(0xFF27292B),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wallpaper_outlined,
                size: 48,
                color: gold,
              ),
              SizedBox(height: 12),
              Text(
                'Todavía no hay una fotografía personalizada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      _heroUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(
          color: Color(0xFF27292B),
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: gold,
            ),
          ),
        );
      },
    );
  }
}
