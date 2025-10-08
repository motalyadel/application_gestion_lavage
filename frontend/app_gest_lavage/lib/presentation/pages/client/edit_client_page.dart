// Updated edit_client_page.dart
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/update_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    print('Client data in EditClientPage: ${widget.client.toMap()}'); // Debug log
    _status = widget.client.status != null
        ? Status.fromString(widget.client.status!)
        : Status.active;
    // Initialize the controller with client data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ClientUpdateController>(context, listen: false);
      controller.initSpecificClient(widget.client);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final controller = Provider.of<ClientUpdateController>(context, listen: false);
    try {
      final success = await controller.save(context, widget.client.id, _status);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client modifié avec succès')),
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
    final controller = Provider.of<ClientUpdateController>(context);

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
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : controller.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        controller.error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.error = null, // Clear error
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Consumer<ClientUpdateController>(
                            builder: (context, updateController, child) {
                              return Column(
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
                                      backgroundImage:
                                          NetworkImage(widget.client.photo!),
                                    ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => updateController.pickPhoto(context),
                                    icon: const Icon(Icons.photo_camera, color: Colors.white),
                                    label: const Text('Changer la photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  if (updateController.photo != null) ...[
                                    const SizedBox(height: 8),
                                    Text('Photo sélectionnée: ${updateController.photo!.name}'),
                                  ],
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: updateController.nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Nom',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.person,
                                          color: Colors.teal),
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Le nom est requis'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: updateController.contactController,
                                    decoration: InputDecoration(
                                      labelText: 'Contact',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.phone,
                                          color: Colors.teal),
                                    ),
                                    validator: (value) {
                                      if (value != null && value.trim().isEmpty)
                                        return null;
                                      const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
                                      const emailRegExp =
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
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
                                    controller: updateController.detailsController,
                                    decoration: InputDecoration(
                                      labelText: 'Détails',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.info,
                                          color: Colors.teal),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<Status>(
                                    value: _status,
                                    decoration: InputDecoration(
                                      labelText: 'Statut',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.toggle_on,
                                          color: Colors.teal),
                                    ),
                                    items: Status.values
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status.name),
                                            ))
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _status = value),
                                    validator: (value) => value == null
                                        ? 'Le statut est requis'
                                        : null,
                                  ),
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              textStyle:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            child: const Text('Modifier le Client'),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}