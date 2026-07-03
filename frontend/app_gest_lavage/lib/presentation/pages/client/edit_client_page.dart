import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/update_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class EditClientPage extends StatefulWidget {
  final Client client;
  const EditClientPage({super.key, required this.client});

  @override
  State<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends State<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  Status? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.client.status != null
        ? Status.fromString(widget.client.status!)
        : Status.active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientUpdateController>(context, listen: false)
          .initSpecificClient(widget.client);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final controller =
        Provider.of<ClientUpdateController>(context, listen: false);
    try {
      final success = await controller.save(context, widget.client.id, _status);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted && controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final controller = Provider.of<ClientUpdateController>(context);

    if (authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        // child: Column(
        //   children: [
        //     const WashOpsHeader(),
        //     Expanded(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: WashTheme.navy),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modifier le Profil Client',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: WashTheme.navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  'ID client : #${widget.client.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 12, color: WashTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: WashTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(color: WashTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WashTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Carte photo + statut
              Container(
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
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: WashTheme.chipGrayBg,
                            backgroundImage: controller.photoBytes != null
                                ? MemoryImage(controller.photoBytes!)
                                : (widget.client.photo != null &&
                                        widget.client.photo!.isNotEmpty)
                                    ? NetworkImage(widget.client.photo!)
                                        as ImageProvider
                                    : null,
                            child: controller.photoBytes == null &&
                                    (widget.client.photo == null ||
                                        widget.client.photo!.isEmpty)
                                ? const Icon(Icons.person,
                                    size: 40, color: WashTheme.navy)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => controller.pickPhoto(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: WashTheme.navy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.client.name ?? 'Sans nom',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: WashTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: WashTheme.chipGrayBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Statut du compte',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: WashTheme.textSecondary)),
                          WashStatusChip(
                            label: _status?.value ?? 'Active',
                            background: _status == Status.active
                                ? WashTheme.chipGreenBg
                                : WashTheme.chipGrayBg,
                            textColor: _status == Status.active
                                ? WashTheme.chipGreenText
                                : WashTheme.chipGrayText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Carte infos client
              Container(
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
                    const Text('Informations Client',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: WashTheme.navy)),
                    const SizedBox(height: 14),
                    _buildFieldLabel('Nom complet'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: controller.nameController,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le nom est requis'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildFieldLabel('Statut du compte'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: WashTheme.chipGrayBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Status>(
                          value: _status,
                          isExpanded: true,
                          items: Status.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFieldLabel('Numéro de téléphone'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: controller.contactController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
                        const emailRegExp = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                        if (!RegExp(phoneRegExp).hasMatch(value) &&
                            !RegExp(emailRegExp).hasMatch(value)) {
                          return 'Contact invalide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Carte notes internes
              Container(
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
                    const Text('Notes Internes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: WashTheme.navy)),
                    const SizedBox(height: 4),
                    const Text(
                      'Visibles uniquement par le personnel.',
                      style: TextStyle(
                          fontSize: 12, color: WashTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: WashTheme.chipGrayBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        //     ),
        //   ],
        // ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WashTheme.textSecondary),
      );

  Widget _buildField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
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
