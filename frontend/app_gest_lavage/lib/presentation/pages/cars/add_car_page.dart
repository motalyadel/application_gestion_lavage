import 'package:app_gest_lavage/presentation/pages/admin/dashboard_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final carController = Provider.of<CarManagementController>(context, listen: false);
    if (authController.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecté. Veuillez vous reconnecter.')),
      );
      return;
    }
    final userId = authController.user!.id;

    await carController.addCar(
      context: context,
      userId: userId,
      marque: _marqueController.text.isNotEmpty ? _marqueController.text : null,
      modele: _modeleController.text.isNotEmpty ? _modeleController.text : null,
      immatriculation: _immatriculationController.text,
    );

    if (mounted) {
      if (carController.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              carController.error!.contains('Utilisateur non connecté')
                  ? 'Veuillez vous reconnecter.'
                  : carController.error!.contains('permission')
                      ? 'Vous n\'avez pas les permissions nécessaires.'
                      : 'Erreur : ${carController.error}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiture ajoutée avec succès')),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carController = Provider.of<CarManagementController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une Voiture'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _marqueController,
                  decoration: InputDecoration(
                    labelText: 'Marque (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modeleController,
                  decoration: InputDecoration(
                    labelText: 'Modèle (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _immatriculationController,
                  decoration: InputDecoration(
                    labelText: 'Immatriculation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer une immatriculation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                carController.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ajouter', style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}