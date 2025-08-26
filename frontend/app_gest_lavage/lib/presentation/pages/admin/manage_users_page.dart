import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/pages/client/add_client_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/edit_client_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  late Future<List<Client>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = ClientService().getAllClients();
  }

  void _refreshClients() {
    setState(() {
      _clientsFuture = ClientService().getAllClients();
    });
  }

  Future<void> _deleteClient(String clientId, String clientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le client "$clientName"?'),
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

    try {
      final clientService = ClientService();
      final success = await clientService.deleteClient(clientId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Client "$clientName" supprimé avec succès')),
        );
        _refreshClients();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la suppression du client: ${success ? "Unknown error" : "API error"}')),
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
            onPressed: _refreshClients,
            tooltip: 'Rafraîchir la liste',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('Navigating to AddClientPage');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClientPage()),
          );
          if (result == true && mounted) {
            print('Client added successfully, refreshing list');
            _refreshClients();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un client',
      ),
      body: FutureBuilder<List<Client>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshClients,
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
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 50, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun client trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final clients = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshClients(),
            color: Colors.teal,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: client.photo != null
                        ? CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(client.photo!),
                            onBackgroundImageError: (_, __) => const Icon(Icons.error),
                          )
                        : const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.person, size: 30, color: Colors.white),
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
                        Text('Contact: ${client.contact ?? 'N/A'}'),
                        Text('Statut: ${client.status ?? 'N/A'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () async {
                            print('Navigating to EditClientPage for client: ${client.id}');
                            try {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditClientPage(client: client),
                                ),
                              );
                              if (result == true && mounted) {
                                print('Client updated successfully, refreshing list');
                                _refreshClients();
                              }
                            } catch (e) {
                              print('Error navigating to EditClientPage: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur d’accès à la page de modification: $e')),
                                );
                              }
                            }
                          },
                          tooltip: 'Modifier le client',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteClient(client.id, client.name ?? 'Sans nom'),
                          tooltip: 'Supprimer le client',
                        ),
                      ],
                    ),
                    onTap: () {
                      print('Navigating to client detail for client: ${client.id}');
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
          );
        },
      ),
    );
  }
}