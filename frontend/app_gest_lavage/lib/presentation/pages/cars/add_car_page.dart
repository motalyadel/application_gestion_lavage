import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

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
  bool _isLoading = false;

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
        const SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await carController.addCar(
      context: context,
      userId: authController.user!.id,
      marque: _marqueController.text.trim().isNotEmpty
          ? _marqueController.text.trim()
          : null,
      modele: _modeleController.text.trim().isNotEmpty
          ? _modeleController.text.trim()
          : null,
      immatriculation: _immatriculationController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Véhicule ajouté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(carController.error ?? 'Erreur lors de l\'ajout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const WashOpsHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Ajouter un Véhicule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: WashTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: WashTheme.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations du Véhicule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: WashTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Entrez les détails ci-dessous pour ajouter un véhicule à votre profil.',
                            style: TextStyle(
                                fontSize: 12, color: WashTheme.textSecondary),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel('Marque (ex: Toyota)'),
                          const SizedBox(height: 6),
                          _buildField(
                            controller: _marqueController,
                            hint: 'ex: Toyota',
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Modèle (ex: Corolla)'),
                          const SizedBox(height: 6),
                          _buildField(
                            controller: _modeleController,
                            hint: 'ex: Corolla',
                          ),
                          const SizedBox(height: 14),
                          _buildLabel(
                              'Plaque d\'immatriculation (ex: 1234AA03)'),
                          const SizedBox(height: 6),
                          _buildField(
                            controller: _immatriculationController,
                            hint: 'ex: 1234AA03',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Ce champ est obligatoire'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Encart d'information
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WashTheme.chipBlueBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: WashTheme.chipBlueText, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Les informations de votre véhicule nous aident à adapter nos cycles de lavage.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: WashTheme.chipBlueText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter le Véhicule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WashTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: WashTheme.textSecondary,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: WashTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: WashTheme.chipGrayBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
