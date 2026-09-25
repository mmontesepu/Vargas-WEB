import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../admin/presentation/admin_access_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _servicesKey = GlobalKey();
  final _projectsKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _testimonialsKey = GlobalKey();
  final _contactKey = GlobalKey();

  static const _muted = Color(0xFFB8B8B8);
  static const _border = Color(0xFF343638);

  // Fotografías referenciales. Reemplazar por imágenes
  // autorizadas de Vargas SPA cuando estén disponibles.
  static const _heroImage =
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1800&q=85';

  static const _constructionImage =
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1000&q=85';

  static const _renovationImage =
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=1000&q=85';

  static const _finishesImage =
      'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=1000&q=85';

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;

    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: 0.03,
    );
  }

  void _openAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminAccessPage(),
      ),
    );
  }

  void _openContact() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ContactDialog(),
    );
  }

  Widget _image(
    String url, {
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Container(
          width: double.infinity,
          height: height,
          color: const Color(0xFF27292B),
          child: const Center(
            child: Icon(
              Icons.home_work_outlined,
              size: 52,
              color: gold,
            ),
          ),
        );
      },
    );
  }

  Widget _eyebrow(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: gold,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      ),
    );
  }

  Widget _sectionHeading(
    String eyebrow,
    String title, {
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(eyebrow),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ],
    );
  }

  Widget _section({
    Key? key,
    required Widget child,
    Color? background,
    double verticalPadding = 76,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(
        horizontal: 22,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }

  Widget _navButton(
    String label,
    GlobalKey key,
  ) {
    return TextButton(
      onPressed: () => _scrollTo(key),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(label),
    );
  }

  Widget _header(bool mobile) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: ink,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  PrimaryScrollController.maybeOf(context)?.animateTo(
                    0,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.architecture,
                          color: gold,
                          size: 34,
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VARGAS SPA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        Text(
                          'CONSTRUCCIONES',
                          style: TextStyle(
                            color: gold,
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!mobile) ...[
                _navButton('Servicios', _servicesKey),
                _navButton('Proyectos', _projectsKey),
                _navButton('Nosotros', _aboutKey),
                _navButton('Testimonios', _testimonialsKey),
                _navButton('Contacto', _contactKey),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _openAdmin,
                  child: const Text('Administración'),
                ),
              ] else
                PopupMenuButton<String>(
                  tooltip: 'Abrir menú',
                  icon: const Icon(Icons.menu),
                  onSelected: (value) {
                    switch (value) {
                      case 'services':
                        _scrollTo(_servicesKey);
                        break;
                      case 'projects':
                        _scrollTo(_projectsKey);
                        break;
                      case 'about':
                        _scrollTo(_aboutKey);
                        break;
                      case 'testimonials':
                        _scrollTo(_testimonialsKey);
                        break;
                      case 'contact':
                        _scrollTo(_contactKey);
                        break;
                      case 'admin':
                        _openAdmin();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'services',
                      child: Text('Servicios'),
                    ),
                    PopupMenuItem(
                      value: 'projects',
                      child: Text('Proyectos'),
                    ),
                    PopupMenuItem(
                      value: 'about',
                      child: Text('Nosotros'),
                    ),
                    PopupMenuItem(
                      value: 'testimonials',
                      child: Text('Testimonios'),
                    ),
                    PopupMenuItem(
                      value: 'contact',
                      child: Text('Contacto'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'admin',
                      child: Text('Administración'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool mobile) {
    return SizedBox(
      width: double.infinity,
      height: mobile ? 640 : 650,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _image(_heroImage),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xF5101214),
                  Color(0xC9101214),
                  Color(0x40101214),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 670),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _eyebrow('Construcción · Remodelación · Terminaciones'),
                      const SizedBox(height: 20),
                      Text(
                        'Construimos espacios que dejan huella.',
                        style: TextStyle(
                          fontSize: mobile ? 39 : 62,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Transformamos tus ideas en proyectos concretos, '
                        'con dedicación, atención al detalle y una relación '
                        'cercana durante cada etapa de la obra.',
                        style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _openContact,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Solicitar cotización'),
                          ),
                          OutlinedButton(
                            onPressed: () => _scrollTo(_projectsKey),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white54,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 18,
                              ),
                            ),
                            child: const Text('Conocer proyectos'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 18,
            bottom: 15,
            child: Text(
              'Fotografía arquitectónica referencial',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(
    IconData icon,
    String title,
    String description,
    String imageUrl,
  ) {
    return Container(
      width: 360,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _image(imageUrl, height: 180),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: gold, size: 27),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _services() {
    return _section(
      key: _servicesKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Nuestros servicios',
            'Soluciones para cada etapa de tu proyecto.',
            description: 'Desde una nueva construcción hasta la renovación '
                'de espacios existentes, trabajamos con atención '
                'a los detalles y a las necesidades de cada cliente.',
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050
                  ? 3
                  : constraints.maxWidth >= 650
                      ? 2
                      : 1;

              const spacing = 16.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _serviceCard(
                      Icons.home_work_outlined,
                      'Construcción',
                      'Desarrollo de proyectos de construcción '
                          'con una ejecución planificada y '
                          'atención a cada etapa.',
                      _constructionImage,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _serviceCard(
                      Icons.construction_outlined,
                      'Remodelaciones',
                      'Renovamos espacios para mejorar su '
                          'funcionalidad, estética y comodidad.',
                      _renovationImage,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _serviceCard(
                      Icons.handyman_outlined,
                      'Terminaciones',
                      'Trabajos de terminación y detalles '
                          'que completan cada proyecto.',
                      _finishesImage,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Imágenes ilustrativas de referencia.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _projects() {
    return _section(
      key: _projectsKey,
      background: const Color(0xFF161819),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 760;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _sectionHeading(
                'Nuestro portafolio',
                'Cada proyecto merece ser mostrado.',
                description: 'Estamos preparando una galería de obras '
                    'con fotografías reales, detalles de ejecución '
                    'y resultados de los trabajos realizados.',
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: gold,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Próximamente: proyectos reales de Vargas SPA.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openContact,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Conversemos sobre tu proyecto'),
              ),
            ],
          );

          final photo = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                _image(_constructionImage, height: mobile ? 260 : 380),
                const Positioned(
                  left: 12,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xE5101214),
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Imagen referencial · Portafolio en preparación',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 26),
                photo,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 45),
              Expanded(child: photo),
            ],
          );
        },
      ),
    );
  }

  Widget _about() {
    const points = [
      (
        Icons.visibility_outlined,
        'Comunicación cercana',
        'Una relación clara durante el desarrollo del proyecto.',
      ),
      (
        Icons.design_services_outlined,
        'Atención al detalle',
        'Cada terminación forma parte del resultado final.',
      ),
      (
        Icons.assignment_outlined,
        'Trabajo organizado',
        'Seguimiento de las etapas y necesidades de la obra.',
      ),
    ];

    return _section(
      key: _aboutKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Sobre nosotros',
            'Más que construir, queremos generar confianza.',
            description: 'En Vargas SPA entendemos que cada proyecto '
                'representa una inversión importante. Por eso '
                'buscamos acompañar a nuestros clientes desde '
                'la idea inicial hasta la entrega del trabajo.',
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 800 ? 3 : 1;
              const spacing = 14.0;

              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final point in points)
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            point.$1,
                            color: gold,
                            size: 25,
                          ),
                          const SizedBox(height: 13),
                          Text(
                            point.$2,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            point.$3,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _testimonials() {
    return _section(
      key: _testimonialsKey,
      background: const Color(0xFF161819),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Experiencias de clientes',
            'La confianza se construye con resultados.',
            description: 'Próximamente compartiremos experiencias '
                'y opiniones de clientes que autoricen '
                'la publicación de sus testimonios.',
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: gold,
                  size: 38,
                ),
                SizedBox(height: 10),
                Text(
                  'Historias reales, proyectos reales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Este espacio se habilitará con testimonios '
                  'verificados y autorizados por nuestros clientes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contact() {
    return _section(
      key: _contactKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 42,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF282015),
              Color(0xFF1B1D1F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: gold.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            _eyebrow('Hablemos de tu próximo proyecto'),
            const SizedBox(height: 13),
            const Text(
              'Tu idea puede comenzar aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cuéntanos qué necesitas construir o remodelar '
              'y preparemos juntos el siguiente paso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 25),
            FilledButton.icon(
              onPressed: _openContact,
              icon: const Icon(Icons.edit_note),
              label: const Text('Preparar solicitud de cotización'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0B0D0F),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VARGAS SPA',
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Construcción · Remodelación · Terminaciones',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _openAdmin,
                child: const Text('Acceso administración'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 950;

          return Column(
            children: [
              _header(mobile),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _hero(constraints.maxWidth < 650),
                      _services(),
                      _projects(),
                      _about(),
                      _testimonials(),
                      _contact(),
                      _footer(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ======================================================
// FORMULARIO PRELIMINAR DE CONTACTO
// ======================================================

class _ContactDialog extends StatefulWidget {
  const _ContactDialog();

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String _service = 'Construcción';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _copyRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final message = '''
SOLICITUD DE COTIZACIÓN - VARGAS SPA

Nombre: ${_nameController.text.trim()}
Teléfono: ${_phoneController.text.trim()}
Correo: ${_emailController.text.trim()}
Servicio: $_service

Descripción del proyecto:
${_messageController.text.trim()}
''';

    await Clipboard.setData(
      ClipboardData(text: message),
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitud copiada. Puedes enviarla por tu canal de contacto preferido.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar cotización'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Completa tus datos para preparar una solicitud. '
                  'Por ahora no se enviará automáticamente.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa tu teléfono'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu correo';
                    }

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(value.trim())) {
                      return 'Ingresa un correo válido';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _service,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de proyecto',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Construcción',
                      child: Text('Construcción'),
                    ),
                    DropdownMenuItem(
                      value: 'Remodelación',
                      child: Text('Remodelación'),
                    ),
                    DropdownMenuItem(
                      value: 'Terminaciones',
                      child: Text('Terminaciones'),
                    ),
                    DropdownMenuItem(
                      value: 'Otro',
                      child: Text('Otro'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _service = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos sobre tu proyecto',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Describe brevemente tu proyecto'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _copyRequest,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copiar solicitud'),
        ),
      ],
    );
  }
}
