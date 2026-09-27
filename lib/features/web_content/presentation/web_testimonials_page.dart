import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../repositories/web_testimonial_repository.dart';

class WebTestimonialsPage extends StatefulWidget {
  const WebTestimonialsPage({super.key});

  @override
  State<WebTestimonialsPage> createState() => _WebTestimonialsPageState();
}

class _WebTestimonialsPageState extends State<WebTestimonialsPage> {
  List<WebTestimonial> _items = [];
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
      final items = await WebTestimonialRepository.getAll();

      if (!mounted) return;

      setState(() {
        _items = items;
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

  Future<void> _openEditor([WebTestimonial? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TestimonialEditor(item: item),
    );

    if (!mounted) return;

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _delete(WebTestimonial item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar testimonio'),
        content: Text(
          '¿Eliminar definitivamente el testimonio de '
          '${item.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await WebTestimonialRepository.delete(item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testimonio eliminado correctamente.'),
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $error')),
      );
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 16,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Testimonios',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Administra las opiniones que aparecen '
                        'en el sitio público.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo testimonio'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _message(
                  'No fue posible cargar los testimonios.\n$_error',
                  Icons.error_outline,
                )
              else if (_items.isEmpty)
                _message(
                  'Todavía no hay testimonios registrados.',
                  Icons.format_quote_outlined,
                )
              else
                ..._items.map(_testimonialCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: gold),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _testimonialCard(WebTestimonial item) {
    final isPublic = item.authorized && item.published;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(22),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.customerRole != null)
                    Text(
                      item.customerRole!,
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
              Chip(
                label: Text(
                  isPublic
                      ? 'Publicado'
                      : item.authorized
                          ? 'Oculto'
                          : 'Sin autorización',
                ),
                avatar: Icon(
                  isPublic ? Icons.public : Icons.visibility_off_outlined,
                  size: 18,
                  color: isPublic ? Colors.greenAccent : gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.testimonial,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          if (item.rating != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => Icon(
                  index < item.rating! ? Icons.star : Icons.star_border,
                  size: 19,
                  color: gold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Orden: ${item.sortOrder} · '
                'Autorización: ${item.authorized ? "Sí" : "No"}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openEditor(item),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  IconButton(
                    tooltip: 'Eliminar testimonio',
                    onPressed: () => _delete(item),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestimonialEditor extends StatefulWidget {
  final WebTestimonial? item;

  const _TestimonialEditor({this.item});

  @override
  State<_TestimonialEditor> createState() => _TestimonialEditorState();
}

class _TestimonialEditorState extends State<_TestimonialEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _testimonial;
  late final TextEditingController _order;

  int? _rating;
  bool _authorized = false;
  bool _published = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _name = TextEditingController(text: item?.customerName ?? '');
    _role = TextEditingController(text: item?.customerRole ?? '');
    _testimonial = TextEditingController(
      text: item?.testimonial ?? '',
    );
    _order = TextEditingController(
      text: (item?.sortOrder ?? 0).toString(),
    );

    _rating = item?.rating;
    _authorized = item?.authorized ?? false;
    _published = item?.published ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _testimonial.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);

    try {
      await WebTestimonialRepository.save(
        id: widget.item?.id,
        customerName: _name.text,
        customerRole: _role.text,
        testimonial: _testimonial.text,
        rating: _rating,
        sortOrder: int.parse(_order.text.trim()),
        authorized: _authorized,
        published: _published,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible guardar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Nuevo testimonio' : 'Editar testimonio',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente *',
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 2 || length > 120) {
                      return 'Ingresa entre 2 y 120 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _role,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Ej.: Cliente de remodelación',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _testimonial,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1500,
                  decoration: const InputDecoration(
                    labelText: 'Testimonio *',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 10 || length > 1500) {
                      return 'Ingresa entre 10 y 1500 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _rating,
                  decoration: const InputDecoration(
                    labelText: 'Valoración (opcional)',
                  ),
                  items: const [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin valoración'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 1,
                      child: Text('1 estrella'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 2,
                      child: Text('2 estrellas'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 3,
                      child: Text('3 estrellas'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 4,
                      child: Text('4 estrellas'),
                    ),
                    DropdownMenuItem<int?>(
                      value: 5,
                      child: Text('5 estrellas'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _rating = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Orden de aparición',
                  ),
                  validator: (value) {
                    if (int.tryParse(value?.trim() ?? '') == null) {
                      return 'Ingresa un número entero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _authorized,
                  title: const Text(
                    'Autorización de publicación registrada',
                  ),
                  subtitle: const Text(
                    'Confirma que el cliente autorizó publicar '
                    'su nombre y opinión en el sitio web.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _authorized = value ?? false;

                      if (!_authorized) {
                        _published = false;
                      }
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _published,
                  title: const Text('Publicar en el sitio web'),
                  subtitle: Text(
                    _authorized
                        ? 'El testimonio será visible públicamente.'
                        : 'Primero debes registrar la autorización.',
                  ),
                  onChanged: _authorized
                      ? (value) {
                          setState(() => _published = value);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
