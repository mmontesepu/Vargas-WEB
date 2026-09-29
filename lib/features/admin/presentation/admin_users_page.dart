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
    final passwordController = TextEditingController();

    bool showPassword = false;

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
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Crea una cuenta con acceso completo '
                            'al panel administrativo de Vargas SPA.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Nombre completo
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

                          // Correo electrónico
                          TextFormField(
                            controller: emailController,
                            enabled: !_submitting,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';

                              if (email.length > 254 ||
                                  !RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(email)) {
                                return 'Ingresa un correo válido';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Contraseña temporal
                          TextFormField(
                            controller: passwordController,
                            enabled: !_submitting,
                            obscureText: !showPassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'Contraseña temporal',
                              prefixIcon: const Icon(Icons.lock_outline),
                              helperText: 'Entre 12 y 128 caracteres',
                              suffixIcon: IconButton(
                                tooltip: showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () {
                                  setDialogState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';

                              if (password.length < 12 ||
                                  password.length > 128) {
                                return 'Usa entre 12 y 128 caracteres';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

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
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() {
                              _submitting = true;
                            });

                            try {
                              final response = await Supabase
                                  .instance.client.functions
                                  .invoke(
                                'invite-admin',
                                body: {
                                  'name': nameController.text.trim(),
                                  'email':
                                      emailController.text.trim().toLowerCase(),
                                  'password': passwordController.text,
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
                                  message ?? 'No se pudo crear el usuario.',
                                );
                              }

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              if (!mounted) return;

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Usuario administrador creado '
                                    'correctamente.',
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
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(
                      _submitting ? 'Creando...' : 'Crear usuario',
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
      passwordController.dispose();
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
                        style: TextStyle(
                          color: Colors.white54,
                        ),
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
                      'Los usuarios creados podrán acceder '
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
