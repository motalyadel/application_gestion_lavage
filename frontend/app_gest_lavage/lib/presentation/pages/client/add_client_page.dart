import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/client_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum Status { active, inactive }

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
  DateTime? _startDate;
  Status? _status;
  bool _isLoading = false;

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
      setState(() => _photo = pickedFile);
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selectedDate != null) {
      setState(() => _startDate = selectedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = Provider.of<ClientManagementController>(context, listen: false);
    try {
      await controller.createClient(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        contact: _contactController.text,
        details: _detailsController.text.isEmpty ? null : _detailsController.text,
        startDate: _startDate,
        status: _status?.name, // Convert Status? to String?
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur créé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      appBar: AppBar(
        title: const Text('Ajouter un Client'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : controller.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        controller.error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.loadClients(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nouveau Client',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.person, color: Colors.teal),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Le nom est requis'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.email, color: Colors.teal),
                                ),
                                validator: (value) => value == null || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value ?? '')
                                    ? 'Email invalide'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                                ),
                                obscureText: true,
                                validator: (value) => value == null || value.length < 6
                                    ? 'Mot de passe doit avoir au moins 6 caractères'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactController,
                                decoration: InputDecoration(
                                  labelText: 'Contact',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
                                    const emailRegExp = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                                    if (!RegExp(phoneRegExp).hasMatch(value) &&
                                        !RegExp(emailRegExp).hasMatch(value)) {
                                      return 'Contact invalide (téléphone ou email)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _detailsController,
                                decoration: InputDecoration(
                                  labelText: 'Détails',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.info, color: Colors.teal),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Date de début',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                                      ),
                                      controller: TextEditingController(
                                        text: _startDate == null
                                            ? 'Sélectionner la date'
                                            : DateFormat.yMMMd().format(_startDate!),
                                      ),
                                      onTap: _selectDate,
                                      validator: (value) => _startDate == null
                                          ? 'La date est requise'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.calendar_today, color: Colors.teal),
                                    onPressed: _selectDate,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<Status>(
                                value: _status,
                                decoration: InputDecoration(
                                  labelText: 'Statut',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.toggle_on, color: Colors.teal),
                                ),
                                items: Status.values.map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.name),
                                )).toList(),
                                onChanged: (value) => setState(() => _status = value),
                                validator: (value) => value == null ? 'Statut requis' : null,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _pickPhoto,
                                child: const Text('Sélectionner une photo'),
                              ),
                              if (_photo != null) const SizedBox(height: 8),
                              if (_photo != null) Text('Photo sélectionnée: ${_photo!.name}'),
                              const SizedBox(height: 24),
                              Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          textStyle: const TextStyle(fontSize: 16),
                                        ),
                                        child: const Text('Ajouter le Client'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),);
  }
}