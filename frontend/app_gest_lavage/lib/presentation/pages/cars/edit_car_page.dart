import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    final carController =
        Provider.of<CarManagementController>(context, listen: false);

    final success = await carController.updateCar(
      context: context,
      id: widget.car.id,
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
            content: Text('Véhicule mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(carController.error ?? 'Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ AJOUT : confirmation avant suppression depuis l'icône poubelle en haut
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce véhicule ?'),
        content: Text(
          '${widget.car.marque ?? ''} ${widget.car.modele ?? ''} (${widget.car.immatriculation}) sera définitivement supprimé.',
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
      setState(() => _isLoading = true);
      final carController =
          Provider.of<CarManagementController>(context, listen: false);
      try {
        await carController.deleteCar(context, widget.car.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Véhicule supprimé')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carController = Provider.of<CarManagementController>(context);

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header custom avec retour + titre + suppression (pas le WashOpsHeader générique ici)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: WashTheme.navy),
                  ),
                  const Expanded(
                    child: Text(
                      'Modifier le Véhicule',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: WashTheme.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Supprimer ce véhicule',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  
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
                          _buildLabel('Marque'),
                          const SizedBox(height: 6),
                          _buildField(
                            controller: _marqueController,
                            hint: 'ex: Toyota',
                            icon: Icons.directions_car_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Modèle'),
                          const SizedBox(height: 6),
                          _buildField(
                            controller: _modeleController,
                            hint: 'ex: Corolla',
                            icon: Icons.category_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Plaque d\'immatriculation'),
                          const SizedBox(height: 6),
                          _buildField(
                            controller: _immatriculationController,
                            hint: 'ex: ABC-1234',
                            icon: Icons.confirmation_number_outlined,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Ce champ est obligatoire'
                                    : null,
                          ),
                        ],
                      ),
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
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Enregistrer les modifications'),
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
                  if (carController.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      carController.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: WashTheme.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: WashTheme.textSecondary),
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
