import 'dart:typed_data';

import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/client_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class AddClientPage extends StatefulWidget {
  const AddClientPage({super.key});

  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _detailsController = TextEditingController();

  XFile? _photo;
  Uint8List? _photoBytes;
  DateTime? _startDate;
  Status? _status = Status.active;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _photo = pickedFile;
        _photoBytes = bytes;
      });
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() => _startDate = selectedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller =
        Provider.of<ClientManagementController>(context, listen: false);
    try {
      await controller.createClient(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        contact: _contactController.text,
        details:
            _detailsController.text.isEmpty ? null : _detailsController.text,
        startDate: _startDate,
        status: _status?.value,
        photo: _photo,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final controller = Provider.of<ClientManagementController>(context);

    if (authController.currentRole != 'admin') {
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
              child: controller.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const WashSectionTitle(
                          title: 'Nouveau Client',
                          subtitle: 'Créer un compte client.',
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCard(
                                title: 'Photo du Client',
                                children: [_buildAvatarPicker()],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: 'Informations de Contact',
                                children: [
                                  _buildLabel('Nom complet'),
                                  const SizedBox(height: 6),
                                  _buildTextField(
                                    controller: _nameController,
                                    hint: 'ex: Jean Dupont',
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Le nom est requis'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLabel('Numéro de téléphone'),
                                  const SizedBox(height: 6),
                                  _buildTextField(
                                    controller: _contactController,
                                    hint: '+222 00 00 00 00',
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        const phoneRegExp =
                                            r'^\+?[1-9]\d{1,14}$';
                                        const emailRegExp =
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                                        if (!RegExp(phoneRegExp)
                                                .hasMatch(value) &&
                                            !RegExp(emailRegExp)
                                                .hasMatch(value)) {
                                          return 'Contact invalide';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLabel('Adresse Email'),
                                  const SizedBox(height: 6),
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'jean.dupont@example.com',
                                    validator: (value) => value == null ||
                                            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)
                                        ? 'Email invalide'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLabel('Mot de passe (accès système)'),
                                  const SizedBox(height: 6),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: '••••••••••',
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 18,
                                        color: WashTheme.textSecondary,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (value) =>
                                        value == null || value.length < 6
                                            ? 'Au moins 6 caractères'
                                            : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCard(
                                title: 'Détails Opérationnels',
                                children: [
                                  _buildLabel('Date de début'),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _selectDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: WashTheme.chipGrayBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _startDate == null
                                                  ? 'mm/dd/yyyy'
                                                  : DateFormat.yMMMd()
                                                      .format(_startDate!),
                                              style: TextStyle(
                                                color: _startDate == null
                                                    ? WashTheme.textSecondary
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today,
                                              size: 18,
                                              color: WashTheme.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLabel('Statut'),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: WashTheme.chipGrayBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Status>(
                                        value: _status,
                                        isExpanded: true,
                                        icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: WashTheme.textSecondary),
                                        items: Status.values
                                            .map((s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(s.value),
                                                ))
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _status = v),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLabel('Notes & Exigences spécifiques'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _detailsController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Préférences véhicule ou notes d\'entretien...',
                                      hintStyle: const TextStyle(
                                          color: WashTheme.textSecondary,
                                          fontSize: 13),
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
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: const Text(
                                        'Annuler',
                                        style: TextStyle(
                                          color: WashTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isLoading ? null : _submitForm,
                                      icon: _isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.person_add_alt,
                                              size: 18),
                                      label: const Text('Ajouter le Client'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: WashTheme.navy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (controller.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              controller.error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
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

  // ---------------------------------------------------------------------
  // HELPERS UI
  // ---------------------------------------------------------------------

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WashTheme.navy,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: InkWell(
        onTap: _pickPhoto,
        borderRadius: BorderRadius.circular(60),
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WashTheme.chipGrayBg,
            border: Border.all(
              color: WashTheme.border,
              width: 1.5,
            ),
          ),
          child: _photoBytes != null
              ? ClipOval(
                  child: Image.memory(
                    _photoBytes!,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: WashTheme.navy, size: 26),
                    SizedBox(height: 6),
                    Text(
                      'Ajouter une photo',
                      style: TextStyle(
                          fontSize: 11, color: WashTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: WashTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: WashTheme.chipGrayBg,
        suffixIcon: suffixIcon,
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
