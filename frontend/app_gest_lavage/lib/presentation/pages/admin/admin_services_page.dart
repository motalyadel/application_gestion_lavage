import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_colors.dart';


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

  Future<void> _showEditServiceDialog(
      BuildContext context, Service service) async {
    final nameController = TextEditingController(text: service.name);
    final descriptionController =
        TextEditingController(text: service.description);
    final priceController =
        TextEditingController(text: service.price.toString());
    final durationController =
        TextEditingController(text: service.duration.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix (UM)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service mis à jour avec succès')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<ServiceManagementController>(context, listen: false)
                        .error ??
                    'Échec de la mise à jour du service',
              ),
            ),
          );
        }
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
        title: const Text('Ajouter un Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix (UM)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service ajouté avec succès')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<ServiceManagementController>(context, listen: false)
                        .error ??
                    'Échec de l\'ajout du service',
              ),
            ),
          );
        }
      }
    }
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
      appBar: AppBar(
        title: const Text('Gestion des Services'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => serviceController.loadServices(context),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: serviceController.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : serviceController.error != null &&
                  serviceController.services.isEmpty
              ? Center(child: Text(serviceController.error!))
              : serviceController.services.isEmpty
                  ? const Center(child: Text('Aucun service trouvé'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: serviceController.services.length,
                      itemBuilder: (context, index) {
                        final service = serviceController.services[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.build,
                                color: AppColors.primary),
                            title: Text(
                              service.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Prix: ${service.price} UM\nDurée: ${service.duration} min\n${service.description ?? ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppColors.primary),
                              onPressed: () =>
                                  _showEditServiceDialog(context, service),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
