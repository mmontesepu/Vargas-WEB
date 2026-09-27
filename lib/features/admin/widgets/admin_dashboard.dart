import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../clients/models/client.dart';
import '../../projects/models/project.dart';
import '../../quotes/models/quote.dart';

class AdminDashboard extends StatelessWidget {
  final List<Quote> quotes;
  final List<Client> clients;
  final List<Project> projects;
  final ValueChanged<int> onNavigate;
  final Future<void> Function() onRefresh;

  const AdminDashboard({
    super.key,
    required this.quotes,
    required this.clients,
    required this.projects,
    required this.onNavigate,
    required this.onRefresh,
  });

  static const _border = Color(0xFF303338);
  static const _muted = Color(0xFF969BA3);

  String _money(num value) {
    final formatted = value.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
    return '\$$formatted';
  }

  Widget _surface({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _heading(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
    required String detail,
    Color accent = gold,
  }) {
    return _surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final ratio = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 42,
                child: Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcut(
    IconData icon,
    String title,
    String subtitle,
    int index,
  ) {
    return Material(
      color: const Color(0xFF24272A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onNavigate(index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: gold, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: gold,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approved =
        quotes.where((q) => q.status.toLowerCase() == 'aprobada').length;

    final totalQuoted = quotes.fold<double>(
      0,
      (sum, q) => sum + q.total,
    );

    final totalApproved = quotes
        .where((q) => q.status.toLowerCase() == 'aprobada')
        .fold<double>(0, (sum, q) => sum + q.total);

    final planning = projects.where((p) => p.status == 'Planificación').length;

    final active = projects.where((p) => p.status == 'En ejecución').length;

    final finished = projects.where((p) => p.status == 'Finalizado').length;

    final other = projects.length - planning - active - finished;

    final totalBudget = projects.fold<double>(
      0,
      (sum, p) => sum + p.budget,
    );

    final recentQuotes = [...quotes]..sort((a, b) => b.date.compareTo(a.date));

    final recentProjects = [...projects]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 760;
        final columns = width >= 1050
            ? 4
            : width >= 580
                ? 2
                : 1;
        const gap = 12.0;
        final contentWidth = width - (compact ? 32 : 48);
        final metricWidth = (contentWidth - gap * (columns - 1)) / columns;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PANEL DE CONTROL',
                                style: TextStyle(
                                  color: gold,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Resumen general',
                                style: TextStyle(
                                  fontSize: compact ? 24 : 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Indicadores comerciales y operativos.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'Actualizar indicadores',
                          onPressed: () => onRefresh(),
                          icon: const Icon(Icons.refresh, size: 19),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: metricWidth,
                          child: _metric(
                            icon: Icons.description_outlined,
                            label: 'Cotizaciones',
                            value: '${quotes.length}',
                            detail: 'Total registradas',
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _metric(
                            icon: Icons.check_circle_outline,
                            label: 'Aprobadas',
                            value: '$approved',
                            detail: 'Cotizaciones aprobadas',
                            accent: const Color(0xFF61C994),
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _metric(
                            icon: Icons.payments_outlined,
                            label: 'Total cotizado',
                            value: _money(totalQuoted),
                            detail: 'IVA incluido',
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _metric(
                            icon: Icons.people_outline,
                            label: 'Clientes',
                            value: '${clients.length}',
                            detail: 'Clientes registrados',
                            accent: const Color(0xFF83B5ED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, area) {
                        final horizontal = area.maxWidth >= 850;
                        final left = _surface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(
                                'Resumen comercial',
                                subtitle:
                                    'Valores acumulados de las cotizaciones.',
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Monto aprobado',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _money(totalApproved),
                                style: const TextStyle(
                                  color: gold,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: _border),
                              const SizedBox(height: 13),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Presupuesto de costos de proyectos',
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _money(totalBudget),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Proyectos registrados',
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${projects.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        final right = _surface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(
                                'Estado de proyectos',
                                subtitle:
                                    '${projects.length} obras registradas',
                              ),
                              const SizedBox(height: 24),
                              _statusRow(
                                'Planificación',
                                planning,
                                projects.length,
                                gold,
                              ),
                              _statusRow(
                                'En ejecución',
                                active,
                                projects.length,
                                const Color(0xFF83B5ED),
                              ),
                              _statusRow(
                                'Finalizados',
                                finished,
                                projects.length,
                                const Color(0xFF61C994),
                              ),
                              _statusRow(
                                'Otros estados',
                                other,
                                projects.length,
                                const Color(0xFFB2A0DB),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => onNavigate(3),
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                  ),
                                  label: const Text('Ver proyectos'),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (!horizontal) {
                          return Column(
                            children: [
                              left,
                              const SizedBox(height: 14),
                              right,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 14),
                            Expanded(child: right),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, area) {
                        final horizontal = area.maxWidth >= 850;

                        final activity = _surface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(
                                'Registros recientes',
                                subtitle: 'Últimas cotizaciones y proyectos.',
                              ),
                              const SizedBox(height: 16),
                              if (recentQuotes.isEmpty &&
                                  recentProjects.isEmpty)
                                const Text(
                                  'Aún no existen registros.',
                                  style: TextStyle(color: _muted),
                                ),
                              ...recentQuotes.take(3).map(
                                    (q) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.description_outlined,
                                        color: gold,
                                        size: 20,
                                      ),
                                      title: Text(
                                        q.id,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      subtitle: Text(
                                        q.client,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: Text(
                                        _money(q.total),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onTap: () => onNavigate(1),
                                    ),
                                  ),
                              ...recentProjects.take(2).map(
                                    (p) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.apartment_outlined,
                                        color: gold,
                                        size: 20,
                                      ),
                                      title: Text(
                                        p.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      subtitle: Text(
                                        p.clientName,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: Text(
                                        p.status,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      onTap: () => onNavigate(3),
                                    ),
                                  ),
                            ],
                          ),
                        );

                        final shortcuts = _surface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(
                                'Accesos rápidos',
                                subtitle: 'Administración del negocio.',
                              ),
                              const SizedBox(height: 16),
                              _shortcut(
                                Icons.description_outlined,
                                'Cotizaciones',
                                'Consultar y gestionar',
                                1,
                              ),
                              const SizedBox(height: 10),
                              _shortcut(
                                Icons.people_outline,
                                'Clientes',
                                'Administrar clientes',
                                2,
                              ),
                              const SizedBox(height: 10),
                              _shortcut(
                                Icons.apartment_outlined,
                                'Obras / Proyectos',
                                'Seguimiento de obras',
                                3,
                              ),
                              const SizedBox(height: 10),
                              _shortcut(
                                Icons.photo_library_outlined,
                                'Portafolio público',
                                'Gestionar contenido web',
                                4,
                              ),
                            ],
                          ),
                        );

                        if (!horizontal) {
                          return Column(
                            children: [
                              activity,
                              const SizedBox(height: 14),
                              shortcuts,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: activity),
                            const SizedBox(width: 14),
                            Expanded(child: shortcuts),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
