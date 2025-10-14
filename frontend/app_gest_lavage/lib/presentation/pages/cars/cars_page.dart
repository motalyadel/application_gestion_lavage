import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/presentation/pages/admin/dashboard_page.dart';
import 'package:app_gest_lavage/presentation/pages/cars/add_car_page.dart';
import 'package:app_gest_lavage/presentation/pages/cars/edit_car_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CarManagementController>(context, listen: false)
          .loadCars(context);
    });
  }

  Future<void> _deleteCar(BuildContext context, String carId) async {
    final carController =
        Provider.of<CarManagementController>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette voiture ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await carController.deleteCar(context, carId);
      if (mounted) {
        if (carController.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(carController.error!)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voiture supprimée avec succès')),
          );
          Navigator.pop(
              context, true); // Return true to trigger refresh in DashboardPage
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final carController = Provider.of<CarManagementController>(context);

    if (authController.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Voitures'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => carController.loadCars(context),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: carController.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : carController.error != null
              ? Center(child: Text(carController.error!))
              : carController.cars.isEmpty
                  ? const Center(child: Text('Aucune voiture trouvée'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: carController.cars.length,
                      itemBuilder: (context, index) {
                        final car = carController.cars[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car,
                                color: AppColors.primary),
                            title: Text(
                              '${car.marque ?? 'Inconnu'} ${car.modele ?? 'Inconnu'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Immatriculation: ${car.immatriculation}${authController.currentRole == 'admin' ? '\nUser ID: ${car.userId}' : ''}',
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: AppColors.primary),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditCarPage(car: car),
                                    ),
                                  );
                                  if (result == true) {
                                    carController.loadCars(context);
                                    Navigator.pop(context,
                                        true); // Return true to trigger refresh in DashboardPage
                                  }
                                } else if (value == 'delete') {
                                  await _deleteCar(context, car.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer',
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCarPage()),
          );
          if (result == true) {
            carController.loadCars(context);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
