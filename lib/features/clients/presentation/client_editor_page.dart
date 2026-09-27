import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/client.dart';

import 'package:flutter/services.dart';

class ClientEditorPage extends StatefulWidget {
  final Client? existing;

  const ClientEditorPage({
    super.key,
    this.existing,
  });

  @override
  State<ClientEditorPage> createState() => _ClientEditorPageState();
}

class _ClientEditorPageState extends State<ClientEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _rut;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();

    final client = widget.existing;

    _name = TextEditingController(
      text: client?.name ?? '',
    );

    _rut = TextEditingController(
      text: formatChileanRut(client?.rut ?? ''),
    );

    _email = TextEditingController(
      text: client?.email ?? '',
    );

    _phone = TextEditingController(
      text: formatChileanMobile(client?.phone ?? ''),
    );

    _address = TextEditingController(
      text: client?.address ?? '',
    );

    _notes = TextEditingController(
      text: client?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _rut.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        title: Text(
          editing ? 'Editar cliente' : 'Nuevo cliente',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 750,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing ? 'Información del cliente' : 'Registrar cliente',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mantén actualizados los datos comerciales y de contacto.',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _field(
                    controller: _name,
                    label: 'Nombre / Razón social',
                    icon: Icons.business_outlined,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rut,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'RUT (opcional)',
                      hintText: '12.345.678-5',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final formatted = formatChileanRut(newValue.text);

                        return TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }),
                    ],
                    validator: (value) {
                      final rut = value?.trim() ?? '';

                      if (rut.isEmpty) return null;

                      if (!isValidChileanRut(rut)) {
                        return 'Ingresa un RUT chileno válido';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _email,
                          label: 'Correo electrónico',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Celular',
                            hintText: '+56 9 1234 5678',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                              final formatted =
                                  formatChileanMobile(newValue.text);

                              return TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }),
                          ],
                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.isEmpty) return null;

                            if (!RegExp(r'^\+56 9 \d{4} \d{4}$')
                                .hasMatch(phone)) {
                              return 'Ingresa un celular válido: +56 9 1234 5678';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _address,
                    label: 'Dirección',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          editing ? 'Guardar cambios' : 'Crear cliente',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }

              return null;
            }
          : null,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();

    final client = Client(
      id: widget.existing?.id ?? 'CLI-${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      rut: _rut.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      notes: _notes.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
    );

    Navigator.pop(
      context,
      client,
    );
  }

  String formatChileanRut(String input) {
    final clean = input.toUpperCase().replaceAll(
          RegExp(r'[^0-9K]'),
          '',
        );

    if (clean.isEmpty) return '';

    final limited = clean.length > 9 ? clean.substring(0, 9) : clean;

    if (limited.length == 1) return limited;

    final body = limited.substring(0, limited.length - 1);
    final dv = limited.substring(limited.length - 1);

    final formattedBody = body.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return '$formattedBody-$dv';
  }

  bool isValidChileanRut(String input) {
    final clean = input.toUpperCase().replaceAll(
          RegExp(r'[^0-9K]'),
          '',
        );

    if (clean.length < 2 || clean.length > 9) return false;

    final body = clean.substring(0, clean.length - 1);
    final dv = clean.substring(clean.length - 1);

    if (!RegExp(r'^\d+$').hasMatch(body)) return false;

    var sum = 0;
    var multiplier = 2;

    for (var i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }

    final remainder = 11 - (sum % 11);

    final expectedDv = remainder == 11
        ? '0'
        : remainder == 10
            ? 'K'
            : remainder.toString();

    return dv == expectedDv;
  }

  String formatChileanMobile(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('56')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('9')) {
      digits = digits.substring(1);
    }

    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    if (digits.isEmpty) {
      return input.trim().isEmpty ? '' : '+56 9';
    }

    if (digits.length <= 4) {
      return '+56 9 $digits';
    }

    return '+56 9 ${digits.substring(0, 4)} '
        '${digits.substring(4)}';
  }
}
