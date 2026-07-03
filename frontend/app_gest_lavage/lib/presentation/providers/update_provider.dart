import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:provider/provider.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';

class ClientUpdateController extends ChangeNotifier {
  bool loading = false;
  String? error;
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final detailsController = TextEditingController();
  XFile? photo;
  Uint8List? photoBytes; // ✅ AJOUT : pour l'aperçu, compatible web + mobile

  void initSpecificClient(Client client) {
    nameController.text = client.name ?? '';
    contactController.text = client.contact ?? '';
    detailsController.text = client.details ?? '';
    photo = null;
    photoBytes = null;
    notifyListeners();
  }

  Future<void> pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // ✅ AJOUT
      photo = pickedFile;
      photoBytes = bytes; // ✅ AJOUT
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

      // ✅ MODIFIÉ : plus d'upload manuel séparé — le fichier est envoyé
      // directement à /update-client, qui gère l'upload côté backend.
      final success = await ClientService().updateClient(
        userId: clientId,
        name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        contact: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
        details: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
        status: status,
        photo: photo, // ✅ XFile directement, plus d'URL pré-uploadée
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