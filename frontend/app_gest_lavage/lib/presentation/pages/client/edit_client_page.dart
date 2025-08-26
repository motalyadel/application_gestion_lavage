import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditClientPage extends StatefulWidget {
  final Client client;

  const EditClientPage({super.key, required this.client});

  @override
  State<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends State<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _detailsController;
  XFile? _photo;
  DateTime? _startDate;
  Status? _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name ?? '');
    _contactController =
        TextEditingController(text: widget.client.contact ?? '');
    _detailsController =
        TextEditingController(text: widget.client.details ?? '');
    _startDate = widget.client.startDate;
    _status = widget.client.status != null
        ? Status.fromString(widget.client.status!)
        : Status.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Sélectionner la date de début',
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    if (authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le Client'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modifier le Client',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.client.photo != null &&
                        widget.client.photo!.isNotEmpty)
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(widget.client.photo!),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.teal),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Le nom est requis'
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
                      validator: (value) {
                        if (value != null && value.trim().isEmpty) return null;
                        const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
                        const emailRegExp = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                        if (value != null &&
                            !RegExp(phoneRegExp).hasMatch(value) &&
                            !RegExp(emailRegExp).hasMatch(value)) {
                          return 'Contact invalide (doit être un numéro de téléphone ou email)';
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
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _startDate == null
                            ? 'Sélectionner la date de début'
                            : DateFormat.yMMMd().format(_startDate!),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Date de début',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today,
                            color: Colors.teal),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) => _startDate == null
                          ? 'La date de début est requise'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Status>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            const Icon(Icons.toggle_on, color: Colors.teal),
                      ),
                      items: Status.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.value),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _status = value),
                      validator: (value) =>
                          value == null ? 'Le statut est requis' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickPhoto,
                          child: const Text('Changer la photo'),
                        ),
                        const SizedBox(width: 8),
                        if (_photo != null) const Text('Photo sélectionnée'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final clientService = ClientService();
                            final success = await clientService.updateClient(
                              userId: widget.client.id,
                              role: 'client',
                              name: _nameController.text,
                              contact: _contactController.text.isEmpty
                                  ? null
                                  : _contactController.text,
                              details: _detailsController.text.isEmpty
                                  ? null
                                  : _detailsController.text,
                              photo: _photo,
                              startDate: _startDate,
                              status: _status,
                              email: null,
                            );
                            if (success && mounted) {
                              Navigator.pop(context, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Client modifié avec succès'),
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Échec de la modification'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text('Modifier le Client'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
