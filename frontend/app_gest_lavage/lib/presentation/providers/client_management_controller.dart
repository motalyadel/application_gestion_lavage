import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';

class ClientManagementController extends ChangeNotifier {
  final ClientService _service = ClientService();

  List<Client> clients = [];
  bool loading = false;
  String? error;

  ClientManagementController();

  Future<void> loadClients() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      clients = await _service.getAllClients();
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Échec du chargement des clients : $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createClient({
    required String name,
    required String email,
    required String password,
    required String contact,
    String? details,
    DateTime? startDate,
    String? status,
    XFile? photo,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.createUser(
        email: email,
        password: password,
        name: name,
        contact: contact,
        details: details,
        startDate: startDate,
        status: status,
        roles: ['client'],
        photo: photo,
      );
      if (success) {
        await loadClients();
      } else {
        throw Exception('Échec de la création');
      }
    } catch (e) {
      error = 'Échec de la création du client : $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> registerClient({
    required String name,
    required String email,
    required String password,
    required String contact,
    DateTime? startDate,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.registerAndConfirmClient(
        name: name,
        email: email,
        password: password,
        contact: contact,
        start_date:
            startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      );
      if (success) {
        await loadClients();
      } else {
        throw Exception('Échec de l\'inscription');
      }
    } catch (e) {
      error = 'Échec de l\'inscription du client : $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateClient({
    required String id,
    String? name,
    String? contact,
    String? details,
    Status? status,
    DateTime?
        startDate, // ✅ AJOUT : pour rester cohérent avec _service.updateClient
    XFile?
        photo, // ✅ AJOUT : remplace l'ancien `email`/`role` qui n'existent plus
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateClient(
        userId: id,
        name: name,
        contact: contact,
        details: details,
        status: status,
        startDate: startDate, // ✅ AJOUT
        photo: photo, // ✅ MODIFIÉ : plus de `role` ni `email`
      );
      if (success) {
        await loadClients();
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      error = 'Échec de la mise à jour du client : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.deleteClient(id);
      if (success) {
        await loadClients();
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      error = 'Échec de la suppression du client : $e';
      loading = false;
      notifyListeners();
    }
  }
}
