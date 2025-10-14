import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/presentation/pages/admin/dashboard_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditCarPage extends StatefulWidget {
  final Car car;

  const EditCarPage({super.key, required this.car});

  @override
  State<EditCarPage> createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _marqueController;
  late final TextEditingController _modeleController;
  late final TextEditingController _immatriculationController;

  @override
  void initState() {
    super.initState();
    _marqueController = TextEditingController(text: widget.car.marque);
    _modeleController = TextEditingController(text: widget.car.modele);
    _immatriculationController =
        TextEditingController(text: widget.car.immatriculation);
  }

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
    final carController =
        Provider.of<CarManagementController>(context, listen: false);
    if (authController.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Utilisateur non connecté. Veuillez vous reconnecter.')),
      );
      return;
    }

    await carController.updateCar(
      context: context,
      id: widget.car.id,
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
          const SnackBar(content: Text('Voiture mise à jour avec succès')),
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
        title: const Text('Modifier une Voiture'),
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
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
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
                        child: const Text('Mettre à jour',
                            style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
