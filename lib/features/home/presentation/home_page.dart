import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../admin/presentation/admin_access_page.dart';

import '../../web_content/models/web_project.dart';
import '../../web_content/repositories/web_project_repository.dart';
import '../../web_content/repositories/web_project_image_repository.dart';
import '../../web_content/presentation/public_project_detail_page.dart';
import '../../web_content/repositories/web_service_image_repository.dart';

import '../../web_content/repositories/web_site_settings_repository.dart';

import '../../web_content/repositories/web_testimonial_repository.dart';

import '../repositories/quote_request_repository.dart';

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

  List<WebProject> _publicProjects = [];
  Map<String, String> _projectCoverUrls = {};

  Map<String, String> _serviceImageUrls = {};

  String? _heroImageUrl;

  List<WebTestimonial> _publicTestimonials = [];
  bool _loadingTestimonials = true;

  bool _loadingProjects = true;
  String? _projectsError;

  @override
  void initState() {
    super.initState();

    _loadPublicProjects();
    _loadServiceImages();
    _loadHeroImage();
    _loadTestimonials();
  }

  Future<void> _loadPublicProjects() async {
    setState(() {
      _loadingProjects = true;
      _projectsError = null;
    });

    try {
      final projects = await WebProjectRepository.getPublished();
      final urls = <String, String>{};

      for (final project in projects) {
        final path = project.coverPath;

        if (path == null || path.trim().isEmpty) continue;

        urls[project.id] = await WebProjectImageRepository.signedUrl(path);
      }

      if (!mounted) return;

      setState(() {
        _publicProjects = projects;
        _projectCoverUrls = urls;
        _loadingProjects = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _projectsError = error.toString();
        _loadingProjects = false;
      });
    }
  }

  Future<void> _loadServiceImages() async {
    try {
      final paths = await WebServiceImageRepository.getAll();
      final urls = <String, String>{};

      for (final entry in paths.entries) {
        final path = entry.value;

        if (path == null || path.trim().isEmpty) continue;

        try {
          urls[entry.key] = await WebServiceImageRepository.signedUrl(path);
        } catch (error) {
          debugPrint(
            'No fue posible cargar la imagen del servicio '
            '${entry.key}: $error',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _serviceImageUrls = urls;
      });
    } catch (error) {
      debugPrint('No fue posible cargar las imágenes de servicios: $error');
    }
  }

  Future<void> _loadHeroImage() async {
    try {
      final path = await WebSiteSettingsRepository.getHeroPath();

      String? url;

      if (path != null && path.trim().isNotEmpty) {
        url = await WebSiteSettingsRepository.signedUrl(path);
      }

      if (!mounted) return;

      setState(() {
        _heroImageUrl = url;
      });
    } catch (error) {
      debugPrint(
        'No fue posible cargar la fotografía principal: $error',
      );

      if (!mounted) return;

      setState(() {
        _heroImageUrl = null;
      });
    }
  }

  Future<void> _loadTestimonials() async {
    try {
      final items = await WebTestimonialRepository.getPublished();

      if (!mounted) return;

      setState(() {
        _publicTestimonials = items;
        _loadingTestimonials = false;
      });
    } catch (error) {
      debugPrint(
        'No fue posible cargar los testimonios públicos: $error',
      );

      if (!mounted) return;

      setState(() {
        _publicTestimonials = [];
        _loadingTestimonials = false;
      });
    }
  }

  void _openPublicProject(WebProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicProjectDetailPage(
          project: project,
        ),
      ),
    );
  }

  Future<void> _openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminAccessPage(),
      ),
    );

    if (!mounted) return;

    _loadHeroImage();
    _loadServiceImages();
    _loadPublicProjects();
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
          //_image(_heroImageUrl ?? _heroImage),
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
                      _serviceImageUrls['construction'] ?? _constructionImage,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _serviceCard(
                      Icons.construction_outlined,
                      'Remodelaciones',
                      'Renovamos espacios para mejorar su '
                          'funcionalidad, estética y comodidad.',
                      _serviceImageUrls['renovation'] ?? _renovationImage,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _serviceCard(
                      Icons.handyman_outlined,
                      'Terminaciones',
                      'Trabajos de terminación y detalles '
                          'que completan cada proyecto.',
                      _serviceImageUrls['finishes'] ?? _finishesImage,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Nuestro portafolio',
            'Obras que reflejan nuestro trabajo.',
            description: 'Conoce algunos de los proyectos desarrollados '
                'por Vargas SPA Construcciones.',
          ),
          const SizedBox(height: 30),
          if (_loadingProjects)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_projectsError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No fue posible cargar los proyectos.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadPublicProjects,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            )
          else if (_publicProjects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: gold,
                    size: 36,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Estamos preparando nuestro portafolio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pronto compartiremos fotografías '
                    'de nuestras obras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
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
                    for (final project in _publicProjects)
                      SizedBox(
                        width: cardWidth,
                        child: _publicProjectCard(project),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _publicProjectCard(WebProject project) {
    final url = _projectCoverUrls[project.id];

    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPublicProject(project),
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
                        size: 44,
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) =>
                          const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: gold,
                          size: 40,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.category.toUpperCase(),
                    style: const TextStyle(
                      color: gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (project.location.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            project.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Text(
                        'Ver proyecto',
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: gold,
                        size: 17,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Experiencias de clientes',
            'La confianza se construye con resultados.',
            description: 'Conoce las experiencias compartidas '
                'por clientes de Vargas SPA.',
          ),
          const SizedBox(height: 30),
          if (_loadingTestimonials)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(
                  color: gold,
                ),
              ),
            )
          else if (_publicTestimonials.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: gold,
                    size: 36,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Historias reales, proyectos reales.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Próximamente compartiremos experiencias '
                    'y opiniones de clientes que autoricen '
                    'la publicación de sus testimonios.',
                    style: TextStyle(
                      color: Colors.white60,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 16.0;

                final columns = constraints.maxWidth >= 950
                    ? 3
                    : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in _publicTestimonials)
                      SizedBox(
                        width: cardWidth,
                        child: _testimonialCard(item),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _testimonialCard(WebTestimonial item) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote,
            color: gold,
            size: 34,
          ),
          if (item.rating != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => Icon(
                  index < item.rating!
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: gold,
                  size: 20,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            '“${item.testimonial}”',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 14),
          Text(
            item.customerName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (item.customerRole != null &&
              item.customerRole!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              item.customerRole!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
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
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_sending) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
    });

    try {
      final result = await QuoteRequestRepository.send(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        service: _service,
        message: _messageController.text,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(result.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      String errorMessage =
          'No fue posible enviar la cotización. Inténtalo nuevamente.';

      if (error is StateError) {
        errorMessage = error.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(errorMessage),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
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
                  'Completa tus datos y enviaremos tu solicitud '
                  'directamente a Vargas SPA.',
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
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _sendRequest,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: Text(
            _sending ? 'Enviando...' : 'Enviar cotización',
          ),
        ),
      ],
    );
  }
}
