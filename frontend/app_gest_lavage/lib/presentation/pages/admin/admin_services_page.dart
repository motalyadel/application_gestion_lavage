import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  @override
  void initState() {
    super.initState();
    _loadServicesIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadServicesIfNeeded();
  }

  void _loadServicesIfNeeded() {
    final serviceController =
        Provider.of<ServiceManagementController>(context, listen: false);
    if (serviceController.services.isEmpty || serviceController.error != null) {
      serviceController.loadServices(context);
    }
  }

  // ✅ AJOUT : même logique que ClientServicesPage pour deviner icône/couleur via le nom
  ({IconData icon, Color bg, Color fg}) _serviceVisual(String name) {
    final n = name.toLowerCase();
    if (n.contains('ceramic') || n.contains('céramique')) {
      return (icon: Icons.shield, bg: WashTheme.navy, fg: Colors.white);
    }
    if (n.contains('premium') || n.contains('ultimate') || n.contains('detail')) {
      return (
        icon: Icons.auto_awesome,
        bg: WashTheme.chipBlueBg,
        fg: WashTheme.chipBlueText
      );
    }
    if (n.contains('oil') || n.contains('huile') || n.contains('filtre')) {
      return (icon: Icons.build, bg: const Color(0xFF1B4332), fg: Colors.white);
    }
    if (n.contains('interior') || n.contains('intérieur') ||
        n.contains('sanitiz')) {
      return (
        icon: Icons.cleaning_services,
        bg: WashTheme.chipGrayBg,
        fg: WashTheme.chipGrayText
      );
    }
    return (icon: Icons.local_car_wash, bg: WashTheme.navy, fg: Colors.white);
  }

  Future<void> _showEditServiceDialog(
      BuildContext context, Service service) async {
    final nameController = TextEditingController(text: service.name);
    final descriptionController =
        TextEditingController(text: service.description);
    final priceController = TextEditingController(text: service.price.toString());
    final durationController =
        TextEditingController(text: service.duration.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier le Service',
            style: TextStyle(color: WashTheme.navy, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameController, 'Nom'),
              const SizedBox(height: 12),
              _buildDialogField(descriptionController, 'Description', maxLines: 2),
              const SizedBox(height: 12),
              _buildDialogField(priceController, 'Prix (UM)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDialogField(durationController, 'Durée (minutes)',
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: WashTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WashTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success =
          await Provider.of<ServiceManagementController>(context, listen: false)
              .updateService(
        context: context,
        id: service.id,
        name: nameController.text,
        description: descriptionController.text,
        price: int.tryParse(priceController.text),
        duration: int.tryParse(durationController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Service mis à jour avec succès'
                : Provider.of<ServiceManagementController>(context, listen: false)
                        .error ??
                    'Échec de la mise à jour du service'),
          ),
        );
      }
    }
  }

  Future<void> _showAddServiceDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un Service',
            style: TextStyle(color: WashTheme.navy, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameController, 'Nom'),
              const SizedBox(height: 12),
              _buildDialogField(descriptionController, 'Description', maxLines: 2),
              const SizedBox(height: 12),
              _buildDialogField(priceController, 'Prix (UM)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDialogField(durationController, 'Durée (minutes)',
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: WashTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WashTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success =
          await Provider.of<ServiceManagementController>(context, listen: false)
              .addService(
        context: context,
        name: nameController.text,
        description: descriptionController.text,
        price: int.tryParse(priceController.text) ?? 0,
        duration: int.tryParse(durationController.text) ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Service ajouté avec succès'
                : Provider.of<ServiceManagementController>(context, listen: false)
                        .error ??
                    'Échec de l\'ajout du service'),
          ),
        );
      }
    }
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: WashTheme.chipGrayBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final serviceController = Provider.of<ServiceManagementController>(context);

    if (authController.user == null || authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            WashOpsHeader(
              onAvatarTap: () {},
              onNotificationTap: () {},
            ),
            Expanded(
              child: serviceController.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy))
                  : serviceController.error != null &&
                          serviceController.services.isEmpty
                      ? Center(child: Text(serviceController.error!))
                      : RefreshIndicator(
                          onRefresh: () => serviceController.loadServices(context),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: WashSectionTitle(
                                      title: 'Gérer les Services',
                                      subtitle:
                                          'Mettez à jour votre catalogue, vos tarifs et vos durées de lavage.',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: WashTheme.navy),
                                    onPressed: () =>
                                        serviceController.loadServices(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: WashTheme.chipBlueBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 18, color: WashTheme.chipBlueText),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${serviceController.services.length} services actifs',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: WashTheme.chipBlueText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (serviceController.services.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 50),
                                  child: Center(
                                    child: Text(
                                      'Aucun service trouvé',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: WashTheme.textSecondary),
                                    ),
                                  ),
                                )
                              else
                                ...serviceController.services
                                    .map((service) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _buildServiceCard(service),
                                        ))
                                    .toList(),
                              const SizedBox(height: 12),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        size: 22, color: Colors.grey[400]),
                                    const SizedBox(height: 6),
                                    Text(
                                      'FIN DU CATALOGUE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WashTheme.navy,
        onPressed: () => _showAddServiceDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    final visual = _serviceVisual(service.name);

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: visual.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, color: visual.fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: WashTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    WashStatusChip(
                      label: '${service.price} UM • ${service.duration} min',
                      background: WashTheme.chipGreenBg,
                      textColor: WashTheme.chipGreenText,
                    ),
                  ],
                ),
                if (service.description != null &&
                    service.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    service.description!,
                    style: const TextStyle(
                        fontSize: 12.5, color: WashTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: WashTheme.navy, size: 19),
            onPressed: () => _showEditServiceDialog(context, service),
          ),
        ],
      ),
    );
  }
}