import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/presentation/pages/client/edit_client_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class ClientDetailPage extends StatelessWidget {
  const ClientDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final client = ModalRoute.of(context)!.settings.arguments as Client;

    if (authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    final status = client.status != null ? Status.fromString(client.status!) : Status.active;

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: WashTheme.navy),
                  ),
                  const Expanded(
                    child: Text(
                      'Détails du Client',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: WashTheme.navy),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: WashTheme.navy),
                    tooltip: 'Modifier le client',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditClientPage(client: client),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: WashTheme.chipGrayBg,
                      backgroundImage:
                          (client.photo != null && client.photo!.isNotEmpty)
                              ? NetworkImage(client.photo!)
                              : null,
                      child: (client.photo == null || client.photo!.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: WashTheme.navy)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      client.name ?? 'Sans nom',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: WashTheme.navy),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: WashTheme.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Résumé du Compte',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: WashTheme.navy),
                            ),
                          ),
                        ),
                        _buildDetailRow('ID Client', '#${client.id.substring(0, 8).toUpperCase()}'),
                        _buildDivider(),
                        _buildDetailRow('Contact', client.contact ?? 'Non spécifié'),
                        _buildDivider(),
                        _buildStatusRow('Statut', status),
                        _buildDivider(),
                        _buildDetailRow(
                          'Date de début',
                          client.startDate != null
                              ? '${client.startDate!.day}/${client.startDate!.month}/${client.startDate!.year}'
                              : 'Non spécifiée',
                        ),
                        _buildDivider(),
                        _buildDetailRow('Détails', client.details ?? 'Aucune note'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: WashTheme.border);

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WashTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, Status status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WashTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
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
    );
  }
}