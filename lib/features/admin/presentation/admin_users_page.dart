import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_theme.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  bool _submitting = false;

  Future<void> _showCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: panel,
                title: const Row(
                  children: [
                    Icon(Icons.person_add_alt_1, color: gold),
                    SizedBox(width: 12),
                    Expanded(child: Text('Nuevo usuario')),
                  ],
                ),
                content: SizedBox(
                  width: 440,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'La persona recibirá una invitación por correo '
                          'para configurar su acceso al panel administrativo.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: nameController,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.length < 3) {
                              return 'Ingresa el nombre completo';
                            }
                            if (name.length > 120) {
                              return 'El nombre es demasiado largo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          enabled: !_submitting,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(email)) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                              color: gold,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Acceso completo a la administración',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setDialogState(() => _submitting = true);

                            try {
                              final response = await Supabase
                                  .instance.client.functions
                                  .invoke(
                                'invite-admin',
                                body: {
                                  'name': nameController.text.trim(),
                                  'email':
                                      emailController.text.trim().toLowerCase(),
                                },
                              );

                              final data = response.data;

                              if (response.status != 201 ||
                                  data is! Map ||
                                  data['success'] != true) {
                                final message = data is Map
                                    ? data['error']?.toString()
                                    : null;

                                throw Exception(
                                  message ?? 'No se pudo enviar la invitación.',
                                );
                              }

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              if (!mounted) return;

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invitación enviada correctamente.',
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!dialogContext.mounted) return;

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al crear usuario: $error',
                                  ),
                                ),
                              );
                            } finally {
                              _submitting = false;

                              if (dialogContext.mounted) {
                                setDialogState(() {});
                              }
                            }
                          },
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _submitting ? 'Enviando...' : 'Enviar invitación',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuarios y accesos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Administra las personas autorizadas '
                        'para ingresar al panel.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _showCreateUserDialog,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Nuevo usuario'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: gold,
                      size: 32,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Acceso administrativo completo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Todos los usuarios invitados podrán acceder '
                      'a los módulos administrativos de Vargas SPA. '
                      'No se utilizan roles diferenciados.',
                      style: TextStyle(
                        color: Colors.white60,
                        height: 1.5,
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
}
