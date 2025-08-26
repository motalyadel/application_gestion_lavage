import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientDetailPage extends StatelessWidget {
  const ClientDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final client = ModalRoute.of(context)!.settings.arguments as Client;

    // Vérification du rôle dans l'UI
    if (authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Client'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/add_edit_client', arguments: client)
                  .then((success) {
                if (success == true) {
                  Navigator.pop(context, true); // Rafraîchir la liste précédente
                }
              });
            },
            tooltip: 'Modifier le client',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: client.photo != null
                    ? CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(client.photo!),
                      )
                    : const CircleAvatar(
                        radius: 60,
                        child: Icon(Icons.person, size: 60),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  client.name ?? 'Sans nom',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('ID', client.id),
                      _buildInfoRow('Contact', client.contact ?? 'N/A'),
                      _buildInfoRow('Statut', client.status ?? 'N/A'),
                      _buildInfoRow(
                        'Date de début',
                        client.startDate != null
                            ? client.startDate!.toIso8601String().split('T')[0]
                            : 'N/A',
                      ),
                      _buildInfoRow('Détails', client.details ?? 'N/A'),
                      _buildInfoRow(
                        'Rôles',
                        client.roles.map((role) => role.id).join(', '),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}