import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/data/services/service_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServiceManagementController extends ChangeNotifier {
  final ServiceService _service = ServiceService();
  List<Service> services = [];
  bool loading = false;
  String? error;

  ServiceManagementController();

  Future<void> loadServices(BuildContext context) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final authController =
          Provider.of<AuthController>(context, listen: false);
      final isAdmin = authController.currentRole == 'admin';
      services = await _service.getServices(isAdmin: isAdmin);
      print('Services loaded: ${services.length}');
    } catch (e) {
      print('loadServices() failed: $e');
      error = 'Échec du chargement des services : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> addService({
    required BuildContext context,
    required String name,
    String? description,
    required int price,
    required int duration,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.addService(
        name: name,
        description: description,
        price: price,
        duration: duration,
      );
      if (success) {
        await loadServices(context);
        return true;
      } else {
        throw Exception('Échec de l\'ajout du service');
      }
    } catch (e) {
      error = 'Échec de l\'ajout du service : $e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateService({
    required BuildContext context,
    required String id,
    String? name,
    String? description,
    int? price,
    int? duration,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateService(
        id: id,
        name: name,
        description: description,
        price: price,
        duration: duration,
      );
      if (success) {
        services.clear(); // Clear the list to force a fresh fetch
        await loadServices(context);
        return true;
      } else {
        throw Exception('Échec de la mise à jour du service');
      }
    } catch (e) {
      error = 'Échec de la mise à jour du service : $e';
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
