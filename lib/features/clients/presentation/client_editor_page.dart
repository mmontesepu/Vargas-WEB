import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/client.dart';

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
      text: client?.rut ?? '',
    );

    _email = TextEditingController(
      text: client?.email ?? '',
    );

    _phone = TextEditingController(
      text: client?.phone ?? '',
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
                  _field(
                    controller: _rut,
                    label: 'RUT',
                    icon: Icons.badge_outlined,
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
                        child: _field(
                          controller: _phone,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
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
}
