import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/presentation/pages/client/add_client_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/edit_client_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/client_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientManagementController>(context, listen: false)
          .loadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ AJOUT : filtre local sur nom + contact (pas d'email disponible en base)
  List<Client> _filteredClients(List<Client> all) {
    if (_searchQuery.trim().isEmpty) return all;
    final query = _searchQuery.trim().toLowerCase();
    return all.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final contact = (c.contact ?? '').toLowerCase();
      return name.contains(query) || contact.contains(query);
    }).toList();
  }

  Future<void> _deleteClient(String clientId, String clientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content:
            Text('Voulez-vous vraiment supprimer le client "$clientName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: WashTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final controller =
        Provider.of<ClientManagementController>(context, listen: false);
    try {
      await controller.deleteClient(clientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Client "$clientName" supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final controller = Provider.of<ClientManagementController>(context);

    if (authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    final clients = _filteredClients(controller.clients);

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const WashOpsHeader(),
            Expanded(
              child: controller.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy))
                  : controller.error != null
                      ? _buildErrorState(controller)
                      : RefreshIndicator(
                          onRefresh: () async => controller.loadClients(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: WashSectionTitle(
                                      title: 'Gérer les Clients',
                                      subtitle:
                                          'Consultez, modifiez et gérez les comptes clients.',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: WashTheme.navy),
                                    onPressed: () => controller.loadClients(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: WashTheme.chipGrayBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 8, color: WashTheme.navy),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${controller.clients.length} clients enregistrés',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: WashTheme.navy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: WashTheme.cardBackground,
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: WashTheme.border),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (value) => setState(
                                            () => _searchQuery = value),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Rechercher par nom, contact...',
                                          hintStyle: TextStyle(
                                              color: WashTheme.textSecondary),
                                          prefixIcon: Icon(Icons.search,
                                              color: WashTheme.textSecondary),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              if (clients.isEmpty)
                                _buildEmptyState()
                              else
                                ...clients
                                    .map((client) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _buildClientCard(client),
                                        ))
                                    .toList(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WashTheme.navy,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClientPage()),
          );
          if (result == true && mounted) {
            controller.loadClients();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState(ClientManagementController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              controller.error!,
              style:
                  const TextStyle(fontSize: 15, color: WashTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadClients(),
              style: ElevatedButton.styleFrom(
                backgroundColor: WashTheme.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun client trouvé',
            style: TextStyle(fontSize: 16, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    final status = client.status != null
        ? Status.fromString(client.status!)
        : Status.active;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () =>
          Navigator.pushNamed(context, '/client_detail', arguments: client),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WashTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: WashTheme.chipGrayBg,
                  backgroundImage:
                      (client.photo != null && client.photo!.isNotEmpty)
                          ? NetworkImage(client.photo!)
                          : null,
                  child: (client.photo == null || client.photo!.isEmpty)
                      ? const Icon(Icons.person,
                          color: WashTheme.navy, size: 24)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name ?? 'Sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WashTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      WashStatusChip(
                        label: status.value,
                        background: status == Status.active
                            ? WashTheme.chipGreenBg
                            : WashTheme.chipGrayBg,
                        textColor: status == Status.active
                            ? WashTheme.chipGreenText
                            : WashTheme.chipGrayText,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: WashTheme.navy, size: 20),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditClientPage(client: client),
                      ),
                    );
                    if (result == true && mounted) {
                      Provider.of<ClientManagementController>(context,
                              listen: false)
                          .loadClients();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      _deleteClient(client.id, client.name ?? 'Sans nom'),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: WashTheme.border),
            ),
            WashDetailRow(
              icon: Icons.phone_outlined,
              value: client.contact ?? 'Contact non spécifié',
            ),
          ],
        ),
      ),
    );
  }
}
