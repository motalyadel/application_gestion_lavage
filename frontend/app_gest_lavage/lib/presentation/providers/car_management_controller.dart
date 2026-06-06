import 'dart:io';

import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/data/services/car_service.dart';
import 'package:flutter/material.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarManagementController extends ChangeNotifier {
  final CarService _service = CarService();
  List<Car> cars = [];
  bool loading = false;
  String? error;

  CarManagementController();

  Future<void> loadCars(BuildContext context) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      cars = await _service.getAllCars();
      print('Cars loaded: ${cars.length}');
      stdout.flush();
      loading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('loadCars() failed: $e');
      stdout.flush();
      print('Stack trace: $stackTrace');
      stdout.flush();
      error = 'Échec du chargement des voitures : $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> addCar({
    required BuildContext context,
    required String userId,
    String? marque,
    String? modele,
    required String immatriculation,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.addCar(
        userId: userId,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
      );
      if (success) {
        await loadCars(context);
        return true;
      } else {
        throw Exception('Échec de l\'ajout de la voiture');
      }
    } catch (e) {
      error = 'Échec de l\'ajout de la voiture : $e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCar({
    required BuildContext context,
    required String id,
    String? marque,
    String? modele,
    String? immatriculation,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final success = await _service.updateCar(
        id: id,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
      );
      if (success) {
        await loadCars(context);
        return true;
      } else {
        throw Exception('Échec de la mise à jour de la voiture');
      }
    } catch (e) {
      error = 'Échec de la mise à jour de la voiture : $e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteCar(BuildContext context, String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.deleteCar(id);
      if (success) {
        await loadCars(context);
      } else {
        throw Exception(
            'Échec de la suppression de la voiture : vérifiez vos permissions ou l\'ID de la voiture');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('Only admins can delete cars')) {
        errorMessage =
            'Seuls les administrateurs peuvent supprimer des voitures';
      } else if (errorMessage.contains('Car not found')) {
        errorMessage = 'Voiture non trouvée';
      } else if (errorMessage.contains('Connection refused')) {
        errorMessage = 'Erreur de connexion au serveur. Vérifiez votre réseau.';
      }
      error = errorMessage;
      loading = false;
      notifyListeners();
    }
  }
}
