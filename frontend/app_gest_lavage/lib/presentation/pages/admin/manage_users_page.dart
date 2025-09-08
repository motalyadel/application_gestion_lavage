import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/pages/client/add_client_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/edit_client_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/client_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Provider.of<ClientManagementController>(context, listen: false);
      controller.loadClients();
    });
  }

  Future<void> _deleteClient(String clientId, String clientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content:
            Text('Voulez-vous vraiment supprimer le client "$clientName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.teal)),
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
          SnackBar(content: Text('Client "$clientName" supprimé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression: $e')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Clients'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadClients(),
            tooltip: 'Rafraîchir la liste',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClientPage()),
          );
          if (result == true && mounted) {
            controller.loadClients();
          }
        },
        backgroundColor: Colors.teal,
        tooltip: 'Ajouter un client',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : controller.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        controller.error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.loadClients(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : controller.clients.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 50, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun client trouvé',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => controller.loadClients(),
                      color: Colors.teal,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: controller.clients.length,
                        itemBuilder: (context, index) {
                          final client = controller.clients[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: client.photo != null
                                  ? CircleAvatar(
                                      radius: 25,
                                      backgroundImage:
                                          NetworkImage(client.photo!),
                                      onBackgroundImageError: (_, __) =>
                                          const Icon(Icons.error),
                                    )
                                  : const CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.teal,
                                      child: Icon(Icons.person,
                                          size: 30, color: Colors.white),
                                    ),
                              title: Text(
                                client.name ?? 'Sans nom',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact: ${client.contact ?? 'Non spécifié'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Statut: ${client.status ?? 'Non spécifié'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.teal),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditClientPage(client: client),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        controller.loadClients();
                                      }
                                    },
                                    tooltip: 'Modifier le client',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteClient(
                                        client.id, client.name ?? 'Sans nom'),
                                    tooltip: 'Supprimer le client',
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/client_detail',
                                  arguments: client,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
