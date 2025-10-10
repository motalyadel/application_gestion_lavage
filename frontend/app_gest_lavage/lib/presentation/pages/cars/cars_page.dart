
import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/data/services/car_service.dart';
import 'package:app_gest_lavage/presentation/pages/login_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  List<Car> _cars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCars();
    });
  }

  Future<void> _loadCars() async {
    setState(() => _isLoading = true);
    final authController = Provider.of<AuthController>(context, listen: false);
    final service = CarService();
    final isAdmin = authController.currentRole == 'admin';
    try {
      final cars = await service.getCars(isAdmin: isAdmin);
      if (mounted) {
        setState(() {
          _cars = cars;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load cars failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des voitures : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    if (authController.currentRole == null) {
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
            onPressed: _loadCars,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _cars.isEmpty
              ? const Center(child: Text('Aucune voiture trouvée'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car, color: AppColors.primary),
                        title: Text(
                          '${car.marque ?? 'Inconnu'} ${car.modele ?? 'Inconnu'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Immatriculation: ${car.immatriculation}${authController.currentRole == 'admin' ? '\nClient ID: ${car.clientId}' : ''}',
                        ),
                        trailing: authController.currentRole == 'admin'
                            ? const Icon(Icons.edit, color: AppColors.primary)
                            : null,
                        onTap: authController.currentRole == 'admin'
                            ? () {
                                // TODO: Naviguer vers EditCarPage
                              }
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Naviguer vers AddCarPage
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
