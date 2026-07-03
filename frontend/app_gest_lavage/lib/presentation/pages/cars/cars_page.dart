import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/presentation/pages/cars/add_car_page.dart';
import 'package:app_gest_lavage/presentation/pages/cars/edit_car_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Provider.of<CarManagementController>(context, listen: false)
          .loadCars(context);
    }
  }

  Future<void> _confirmDelete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce véhicule ?'),
        content: Text(
          '${car.marque ?? ''} ${car.modele ?? ''} (${car.immatriculation}) sera définitivement supprimé.',
        ),
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

    if (confirmed == true && mounted) {
      final controller =
          Provider.of<CarManagementController>(context, listen: false);
      try {
        await controller.deleteCar(context, car.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Véhicule supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
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
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const WashOpsHeader(),
            Expanded(
              child: carController.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy))
                  : RefreshIndicator(
                      onRefresh: () => carController.loadCars(context),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const WashSectionTitle(
                            title: 'Mes Véhicules',
                            subtitle:
                                'Gérez votre flotte et sélectionnez-les rapidement lors d\'une réservation.',
                          ),
                          const SizedBox(height: 18),
                          if (carController.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                carController.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          if (carController.cars.isEmpty)
                            _buildEmptyState()
                          else
                            ...carController.cars
                                .map((car) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildCarCard(car),
                                    ))
                                .toList(),
                          const SizedBox(height: 8),
                          // _buildPromoBanner(),
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
            MaterialPageRoute(builder: (_) => const AddCarPage()),
          );
          if (result == true && mounted) {
            carController.loadCars(context);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun véhicule enregistré',
            style: TextStyle(fontSize: 16, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    final title = [car.marque, car.modele]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' ');

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
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: WashTheme.chipBlueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.directions_car,
                color: WashTheme.chipBlueText, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Véhicule' : title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WashTheme.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  car.immatriculation,
                  style: const TextStyle(
                      fontSize: 13, color: WashTheme.textSecondary),
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
                MaterialPageRoute(builder: (context) => EditCarPage(car: car)),
              );
              if (result == true && mounted) {
                Provider.of<CarManagementController>(context, listen: false)
                    .loadCars(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(car),
          ),
        ],
      ),
    );
  }

  // Widget _buildPromoBanner() {
  //   return Column(
  //     children: [
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(16),
  //         child: Container(
  //           height: 150,
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             color: WashTheme.chipGrayBg,
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           alignment: Alignment.center,
  //           child: const Icon(Icons.directions_car,
  //               size: 56, color: WashTheme.textSecondary),
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       const Text(
  //         'Ajoutez plus de véhicules pour accélérer vos réservations',
  //         textAlign: TextAlign.center,
  //         style: TextStyle(
  //           fontSize: 13,
  //           fontStyle: FontStyle.italic,
  //           color: WashTheme.textSecondary,
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
