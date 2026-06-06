import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/presentation/pages/cars/add_car_page.dart';
import 'package:app_gest_lavage/presentation/pages/cars/edit_car_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_colors.dart';

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
    final carController = Provider.of<CarManagementController>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette voiture ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Voitures'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => carController.loadCars(context),
          ),
        ],
      ),
      body: carController.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : carController.error != null
              ? Center(child: Text(carController.error!))
              : carController.cars.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune voiture trouvée', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: carController.cars.length,
                      itemBuilder: (context, index) {
                        final car = carController.cars[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_car, color: AppColors.primary, size: 32),
                            ),
                            title: Text(
                              '${car.marque ?? 'Inconnu'} ${car.modele ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              'Immatriculation: ${car.immatriculation}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EditCarPage(car: car)),
                                  );
                                  if (result == true) carController.loadCars(context);
                                } else if (value == 'delete') {
                                  await _deleteCar(context, car.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
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
            MaterialPageRoute(builder: (_) => const AddCarPage()),
          );
          if (result == true) carController.loadCars(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}