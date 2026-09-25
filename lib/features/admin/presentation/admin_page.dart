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

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

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
            const SizedBox(height: 16),
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
            _menuItem(
              index: 4,
              icon: Icons.web_outlined,
              selectedIcon: Icons.web,
              label: 'Contenido web',
            ),
            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.public,
                  color: Colors.white60,
                ),
                title: const Text(
                  'Volver al sitio',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
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
  }) {
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: selected ? gold.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(
            selected ? selectedIcon : icon,
            color: selected ? gold : Colors.white60,
          ),
          title: Text(
            label,
            style: TextStyle(
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

            // Cada vez que volvemos al Dashboard,
            // refrescamos todos los datos.
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
        return 'Contenido web';

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

    final approvedQuotes = _quotes
        .where(
          (quote) => quote.status.toLowerCase() == 'aprobada',
        )
        .length;

    final totalQuoted = _quotes.fold<double>(
      0,
      (sum, quote) => sum + quote.total,
    );

    final activeProjects = _projects
        .where(
          (project) => project.status == 'En ejecución',
        )
        .length;

    final planningProjects = _projects
        .where(
          (project) => project.status == 'Planificación',
        )
        .length;

    final finishedProjects = _projects
        .where(
          (project) => project.status == 'Finalizado',
        )
        .length;

    final totalProjectBudget = _projects.fold<double>(
      0,
      (sum, project) => sum + project.budget,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1300,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen general',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Vista general de la actividad de Vargas SPA.',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 30),

              //
              // INDICADORES PRINCIPALES
              //
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _dashboardCard(
                    icon: Icons.description_outlined,
                    title: 'Cotizaciones',
                    value: '${_quotes.length}',
                    subtitle: 'Total registradas',
                  ),
                  _dashboardCard(
                    icon: Icons.check_circle_outline,
                    title: 'Aprobadas',
                    value: '$approvedQuotes',
                    subtitle: 'Cotizaciones aprobadas',
                  ),
                  _dashboardCard(
                    icon: Icons.attach_money,
                    title: 'Total cotizado',
                    value: _money(totalQuoted),
                    subtitle: 'Monto total cotizado',
                  ),
                  _dashboardCard(
                    icon: Icons.people_outline,
                    title: 'Clientes',
                    value: '${_clients.length}',
                    subtitle: 'Clientes registrados',
                  ),
                  _dashboardCard(
                    icon: Icons.construction_outlined,
                    title: 'Proyectos activos',
                    value: '$activeProjects',
                    subtitle: 'Obras en ejecución',
                  ),
                ],
              ),

              const SizedBox(height: 35),

              //
              // RESUMEN DE PROYECTOS
              //
              Row(
                children: [
                  const Text(
                    'Estado de proyectos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                    label: const Text(
                      'Ver proyectos',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _projectStatusCard(
                    icon: Icons.apartment_outlined,
                    title: 'Total proyectos',
                    value: '${_projects.length}',
                  ),
                  _projectStatusCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Planificación',
                    value: '$planningProjects',
                  ),
                  _projectStatusCard(
                    icon: Icons.construction_outlined,
                    title: 'En ejecución',
                    value: '$activeProjects',
                  ),
                  _projectStatusCard(
                    icon: Icons.check_circle_outline,
                    title: 'Finalizados',
                    value: '$finishedProjects',
                  ),
                  _projectStatusCard(
                    icon: Icons.payments_outlined,
                    title: 'Presupuesto proyectos',
                    value: _money(
                      totalProjectBudget,
                    ),
                    wide: true,
                  ),
                ],
              ),

              const SizedBox(height: 35),

              //
              // ACTIVIDAD RECIENTE
              //
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    const Text(
                      'Actividad reciente',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_projects.isEmpty && _quotes.isEmpty)
                      const Text(
                        'La actividad del sistema aparecerá aquí.',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      )
                    else ...[
                      if (_projects.isNotEmpty)
                        _activityRow(
                          icon: Icons.apartment_outlined,
                          title: 'Proyectos registrados',
                          description:
                              '${_projects.length} proyecto${_projects.length == 1 ? '' : 's'} en el sistema',
                        ),
                      if (_projects.isNotEmpty && _quotes.isNotEmpty)
                        const Divider(
                          height: 28,
                        ),
                      if (_quotes.isNotEmpty)
                        _activityRow(
                          icon: Icons.description_outlined,
                          title: 'Cotizaciones registradas',
                          description:
                              '${_quotes.length} cotización${_quotes.length == 1 ? '' : 'es'} en el sistema',
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
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
