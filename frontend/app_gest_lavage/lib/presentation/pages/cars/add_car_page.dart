import 'package:app_gest_lavage/core/utils/app_colors.dart';
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
        const SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    final success = await carController.addCar(
      context: context,
      userId: authController.user!.id,
      marque: _marqueController.text.trim().isNotEmpty ? _marqueController.text.trim() : null,
      modele: _modeleController.text.trim().isNotEmpty ? _modeleController.text.trim() : null,
      immatriculation: _immatriculationController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voiture ajoutée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(carController.error ?? 'Erreur lors de l\'ajout'),
            backgroundColor: AppColors.error,
          ),
        );
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
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations du véhicule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _marqueController,
                label: 'Marque',
                hint: 'Ex: Toyota',
                isRequired: false,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _modeleController,
                label: 'Modèle',
                hint: 'Ex: Corolla',
                isRequired: false,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _immatriculationController,
                label: 'Immatriculation',
                hint: 'Ex: ABC-1234',
                isRequired: true,
              ),

              const SizedBox(height: 40),

              carController.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Ajouter le véhicule',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
      ),
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty ? 'Ce champ est obligatoire' : null
          : null,
    );
  }
}