import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/client.dart';
import '../repositories/client_repository.dart';
import 'client_editor_page.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  List<Client> _clients = [];
  bool _loading = true;

  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await ClientRepository.getAll();

    if (!mounted) return;

    setState(() {
      _clients = clients;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await ClientRepository.saveAll(_clients);
  }

  Future<void> _edit([
    Client? existing,
  ]) async {
    final result = await Navigator.push<Client>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientEditorPage(
          existing: existing,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final index = _clients.indexWhere(
        (client) => client.id == result.id,
      );

      if (index == -1) {
        _clients.insert(0, result);
      } else {
        _clients[index] = result;
      }
    });

    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final search = _search.trim().toLowerCase();

    final filteredClients = _clients.where((client) {
      if (search.isEmpty) return true;

      return client.name.toLowerCase().contains(search) ||
          client.rut.toLowerCase().contains(search) ||
          client.email.toLowerCase().contains(search) ||
          client.phone.toLowerCase().contains(search);
    }).toList();

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
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestión de clientes',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Administra los clientes de Vargas SPA.',
                          style: TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(
                      Icons.person_add_outlined,
                    ),
                    label: const Text('Nuevo cliente'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _summaryCard(
                    'Clientes',
                    '${_clients.length}',
                    Icons.people_outline,
                  ),
                  _summaryCard(
                    'Con correo',
                    '${_clients.where(
                          (client) => client.email.isNotEmpty,
                        ).length}',
                    Icons.email_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, RUT, correo o teléfono...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_clients.isEmpty)
                _emptyState()
              else if (filteredClients.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: Text(
                      'No se encontraron clientes.',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredClients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final client = filteredClients[index];

                    return _clientCard(client);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: gold,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clientCard(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: gold.withValues(alpha: 0.12),
              child: Text(
                _initials(client.name),
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (client.rut.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      client.rut,
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client.email.isNotEmpty)
                    Text(
                      client.email,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (client.phone.isNotEmpty)
                    Text(
                      client.phone,
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar cliente',
              onPressed: () => _edit(client),
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 55,
            color: gold,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes clientes registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registra tu primer cliente para comenzar.',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(
              Icons.person_add_outlined,
            ),
            label: const Text('Crear cliente'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
