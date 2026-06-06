import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_colors.dart';



class ClientServicesPage extends StatefulWidget {
  const ClientServicesPage({super.key});

  @override
  State<ClientServicesPage> createState() => _ClientServicesPageState();
}

class _ClientServicesPageState extends State<ClientServicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceManagementController>(context, listen: false)
          .loadServices(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final serviceController = Provider.of<ServiceManagementController>(context);

    if (authController.user == null || authController.currentRole != 'client') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Services'),
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
          : serviceController.error != null
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
                          ),
                        );
                      },
                    ),
    );
  }
}
