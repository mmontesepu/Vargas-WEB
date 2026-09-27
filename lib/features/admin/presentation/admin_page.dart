import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

import '../../quotes/presentation/quotes_page.dart';
import '../../quotes/models/quote.dart';
import '../../quotes/repositories/quote_repository.dart';

import '../../clients/presentation/clients_page.dart';
import '../../clients/models/client.dart';
import '../../clients/repositories/client_repository.dart';

import '../../projects/presentation/projects_page.dart';
import '../../projects/models/project.dart';
import '../../projects/repositories/project_repository.dart';
import '../../web_content/presentation/web_projects_page.dart';
import '../../web_content/presentation/web_service_images_page.dart';

import '../../web_content/presentation/web_home_settings_page.dart';

import '../../web_content/presentation/web_testimonials_page.dart';

import '../widgets/admin_dashboard.dart';

import 'admin_users_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  bool _webMenuExpanded = true;

  List<Quote> _quotes = [];
  List<Client> _clients = [];
  List<Project> _projects = [];

  bool _loadingDashboard = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  String _money(num value) => '\$${value.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      )}';

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loadingDashboard = true;
      });
    }

    final quotesFuture = QuoteRepository.getAll();
    final clientsFuture = ClientRepository.getAll();
    final projectsFuture = ProjectRepository.getAll();

    final quotes = await quotesFuture;
    final clients = await clientsFuture;
    final projects = await projectsFuture;

    if (!mounted) return;

    setState(() {
      _quotes = quotes;
      _clients = clients;
      _projects = projects;
      _loadingDashboard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ink,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: panel,
      child: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // LOGO Y ENCABEZADO
            // =====================================================
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 45,
                    height: 45,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VARGAS.SPA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Administración',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // =====================================================
            // MENÚ PRINCIPAL
            // =====================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _menuItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    label: 'Dashboard',
                  ),

                  _menuItem(
                    index: 1,
                    icon: Icons.description_outlined,
                    selectedIcon: Icons.description,
                    label: 'Cotizaciones',
                  ),

                  _menuItem(
                    index: 2,
                    icon: Icons.people_outline,
                    selectedIcon: Icons.people,
                    label: 'Clientes',
                  ),

                  _menuItem(
                    index: 3,
                    icon: Icons.apartment_outlined,
                    selectedIcon: Icons.apartment,
                    label: 'Obras / Proyectos',
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // =================================================
                  // CONTENIDO WEB - MENÚ DESPLEGABLE
                  // =================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Material(
                      color: (_selectedIndex == 4 ||
                              _selectedIndex == 5 ||
                              _selectedIndex == 6 ||
                              _selectedIndex == 7)
                          ? gold.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        leading: Icon(
                          Icons.language_outlined,
                          color: (_selectedIndex == 4 ||
                                  _selectedIndex == 5 ||
                                  _selectedIndex == 6 ||
                                  _selectedIndex == 7)
                              ? gold
                              : Colors.white60,
                        ),
                        title: Text(
                          'Contenido web',
                          style: TextStyle(
                            color: (_selectedIndex == 4 ||
                                    _selectedIndex == 5 ||
                                    _selectedIndex == 6 ||
                                    _selectedIndex == 7)
                                ? gold
                                : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          _webMenuExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white54,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () {
                          setState(() {
                            _webMenuExpanded = !_webMenuExpanded;
                          });
                        },
                      ),
                    ),
                  ),

                  // SUBMENÚ CONTENIDO WEB
                  if (_webMenuExpanded) ...[
                    const SizedBox(height: 4),
                    _menuItem(
                      index: 6,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Página principal',
                      nested: true,
                    ),
                    _menuItem(
                      index: 4,
                      icon: Icons.photo_library_outlined,
                      selectedIcon: Icons.photo_library,
                      label: 'Portafolio público',
                      nested: true,
                    ),
                    _menuItem(
                      index: 5,
                      icon: Icons.image_outlined,
                      selectedIcon: Icons.image,
                      label: 'Imágenes de servicios',
                      nested: true,
                    ),
                    _menuItem(
                      index: 7,
                      icon: Icons.format_quote_outlined,
                      selectedIcon: Icons.format_quote,
                      label: 'Testimonios',
                      nested: true,
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // =================================================
                  // ADMINISTRACIÓN DE USUARIOS
                  // =================================================
                  _menuItem(
                    index: 8,
                    icon: Icons.manage_accounts_outlined,
                    selectedIcon: Icons.manage_accounts,
                    label: 'Usuarios y accesos',
                  ),
                ],
              ),
            ),

            // =====================================================
            // VOLVER AL SITIO WEB
            // =====================================================
            const Divider(height: 1),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.public,
                  color: Colors.white60,
                ),
                title: const Text(
                  'Volver al sitio',
                  style: TextStyle(color: Colors.white70),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    bool nested = false,
  }) {
    final selected = _selectedIndex == index;

    return Padding(
      padding: EdgeInsets.only(
        left: nested ? 28 : 12,
        right: 12,
        top: 3,
        bottom: 3,
      ),
      child: Material(
        color: selected ? gold.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(
            selected ? selectedIcon : icon,
            size: nested ? 20 : 24,
            color: selected ? gold : Colors.white60,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: nested ? 13 : 14,
              color: selected ? gold : Colors.white70,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: () async {
            setState(() {
              _selectedIndex = index;
            });

            if (index == 0) {
              await _loadDashboard();
            }
          },
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      decoration: BoxDecoration(
        color: ink,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _pageTitle(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: gold,
            child: Icon(
              Icons.person,
              color: ink,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrador',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Vargas SPA',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Cotizaciones';

      case 2:
        return 'Clientes';

      case 3:
        return 'Obras / Proyectos';

      case 4:
        return 'Contenido web / Portafolio público';

      case 5:
        return 'Contenido web / Imágenes de servicios';

      case 6:
        return 'Contenido web / Página principal';

      case 7:
        return 'Contenido web / Testimonios';

      case 8:
        return 'Usuarios y accesos';

      default:
        return 'Dashboard';
    }
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 1:
        return const QuotesPage();

      case 2:
        return const ClientsPage();

      case 3:
        return const ProjectsPage();

      case 4:
        return const WebProjectsPage();

      case 5:
        return const WebServiceImagesPage();

      case 6:
        return const WebHomeSettingsPage();

      case 7:
        return const WebTestimonialsPage();

      case 8:
        return const AdminUsersPage();

      default:
        return _buildDashboard();
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    if (_loadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return AdminDashboard(
      quotes: _quotes,
      clients: _clients,
      projects: _projects,
      onRefresh: _loadDashboard,
      onNavigate: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  // ============================================================
  // TARJETAS DASHBOARD
  // ============================================================

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gold.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: gold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: gold,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectStatusCard({
    required IconData icon,
    required String title,
    required String value,
    bool wide = false,
  }) {
    return Container(
      width: wide ? 260 : 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gold.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: gold.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
