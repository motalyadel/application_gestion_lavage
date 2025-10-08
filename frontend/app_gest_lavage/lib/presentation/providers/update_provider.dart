// Updated ClientUpdateController
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:provider/provider.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

class ClientUpdateController extends ChangeNotifier {
  ClientUpdateController() {
    // No init with context here; initSpecificClient will be called externally
  }

  bool loading = false;
  String? error;
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final detailsController = TextEditingController();
  XFile? photo;

  void initSpecificClient(Client client) {
    nameController.text = client.name ?? '';
    contactController.text = client.contact ?? '';
    detailsController.text = client.details ?? '';
    notifyListeners();
  }

  Future<void> pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      photo = pickedFile;
      notifyListeners();
    }
  }

  Future<bool> save(BuildContext context, String clientId, Status? status) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentRole != 'admin') {
        error = 'Rôle non autorisé pour cette mise à jour';
        loading = false;
        notifyListeners();
        return false;
      }
      // Handle photo upload if provided
      String? photoUrl;
      if (photo != null) {
        photoUrl = await ClientService().uploadPhoto(photo!, 'avatars/${clientId}');
        if (photoUrl == null) {
          error = 'Échec du téléchargement de la photo';
          loading = false;
          notifyListeners();
          return false;
        }
      }
      final success = await ClientService().updateClient(
        userId: clientId,
        role: 'client',
        name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        contact: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
        details: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
        status: status,
        email: null,
        photo: photoUrl, // Pass the uploaded photo URL
      );
      if (success) {
        loading = false;
        notifyListeners();
        return true;
      } else {
        error = 'Échec de la mise à jour du profil';
      }
    } catch (e) {
      error = 'Erreur lors de la mise à jour du profil : $e';
      print('Erreur de sauvegarde : $e');
    }
    loading = false;
    notifyListeners();
    return false;
  }

  bool editing = false;
  void toggleEditing() {
    editing = !editing;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    detailsController.dispose();
    super.dispose();
  }
}