import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../admin/presentation/admin_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ink,
        title: const Text(
          'VARGAS.SPA',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPage(),
                ),
              );
            },
            child: const Text('Administración'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 560,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 72,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0E1012),
                    Color(0xFF332015),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1050,
                  ),
                  child: Wrap(
                    spacing: 55,
                    runSpacing: 30,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 520,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'CONSTRUIMOS CON PROPÓSITO',
                              style: TextStyle(
                                color: gold,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Espacios que dejan huella.',
                              style: TextStyle(
                                fontSize: 56,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Proyectos de construcción y remodelación con atención a cada detalle.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 30),
                            FilledButton(
                              onPressed: () => _contact(context),
                              child: const Text(
                                'Solicitar cotización',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 330,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                72,
                24,
                18,
              ),
              child: Text(
                'Lo que hacemos',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (final item in [
                    ('Construcción', Icons.apartment),
                    (
                      'Remodelaciones',
                      Icons.construction,
                    ),
                    ('Terminaciones', Icons.handyman),
                  ])
                    Container(
                      width: 290,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.$2,
                            color: gold,
                            size: 38,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(35),
              color: panel,
              child: const Center(
                child: Text(
                  'VARGAS.SPA  •  CONSTRUCCIONES',
                  style: TextStyle(
                    letterSpacing: 2,
                    color: gold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contact(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Solicitar cotización',
        ),
        content: const Text(
          'Próximamente conectaremos el formulario de contacto. '
          'La sección de cotizaciones ya está disponible para el administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
