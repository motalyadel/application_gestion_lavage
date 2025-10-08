import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/update_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Client? _client;
  List<Map<String, dynamic>> _loginHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientData();
    });
  }

  Future<void> _loadClientData() async {
    setState(() => _isLoading = true);
    final service = ClientService();
    final client = await service.getCurrentClient();
    if (client != null) {
      print('Initializing ClientUpdateController with: $client');
      Provider.of<ClientUpdateController>(context, listen: false)
          .initSpecificClient(client);
      setState(() => _client = client);
    } else {
      print('Failed to load client data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement du profil')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final controller =
        Provider.of<ClientUpdateController>(context, listen: false);
    try {
      final photoUrl = controller.photo != null
          ? await ClientService()
              .uploadPhoto(controller.photo!, 'avatars/${_client!.id}')
          : null;
      final success = await ClientService().updateClientProfile(
        userId: _client!.id,
        name: controller.nameController.text,
        contact: controller.contactController.text,
        details: controller.detailsController.text,
        photo: photoUrl,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        await _loadClientData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    if (authController.currentRole != 'client') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Compte'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading || _client == null
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Consumer<ClientUpdateController>(
                          builder: (context, controller, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: controller.nameController,
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
                                  controller: controller.contactController,
                                  decoration: InputDecoration(
                                    labelText: 'Contact (téléphone ou email)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.contact_phone,
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
                                  controller: controller.detailsController,
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
                                ElevatedButton(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      controller.photo = pickedFile;
                                      controller.notifyListeners();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Choisir une photo'),
                                ),
                                if (controller.photo != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                        'Photo sélectionnée: ${controller.photo!.name}'),
                                  ),
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 16),
                                    ),
                                    child:
                                        const Text('Mettre à jour le profil'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Historique des connexions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _loginHistory.isEmpty
                      ? const Center(
                          child: Text('Aucun historique de connexion'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _loginHistory.length,
                          itemBuilder: (context, index) {
                            final login = _loginHistory[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  'Connexion: ${login['login_time'] ?? 'Inconnu'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Device: ${login['device_info'] ?? 'Non spécifié'}\nIP: ${login['ip_address'] ?? 'Non spécifié'}',
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
