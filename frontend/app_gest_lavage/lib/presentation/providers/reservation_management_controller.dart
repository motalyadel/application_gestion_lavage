import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/data/services/reservation_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationManagementController extends ChangeNotifier {
  final ReservationService _service = ReservationService();
  List<Reservation> reservations = [];
  bool loading = false;
  String? error;

  Future<void> loadReservations(BuildContext context) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final authController =
          Provider.of<AuthController>(context, listen: false);
      final isAdmin = authController.currentRole == 'admin';
      print('Loading reservations for isAdmin: $isAdmin');
      reservations = await _service.getReservations(isAdmin: isAdmin);
      print('Reservations loaded: ${reservations.length}');
      if (reservations.isEmpty) {
        print('No reservations found');
      }
    } catch (e) {
      print('loadReservations() failed: $e');
      error = 'Échec du chargement des réservations : ${e.toString()}';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> startLavage({
    required BuildContext context,
    required String reservationId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.startLavage(
        reservationId: reservationId,
      );

      if (!success) {
        throw Exception('n8n a refusé le démarrage du lavage');
      }

      await loadReservations(context);
      return true;
    } catch (e) {
      error = 'Échec du démarrage du lavage : ${e.toString()}';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> hasActiveReservationForCar(String carId) async {
    final res = await Supabase.instance.client
        .from('reservations')
        .select('id')
        .eq('car_id', carId)
        .neq('status', 'done')
        .limit(1);

    return res.isNotEmpty;
  }

  Future<bool> addReservation({
    required BuildContext context,
    required String clientId,
    required String clientName,
    required String clientPhone,
    required String serviceId,
    required String serviceName,
    required int serviceDuration,
    required String carId,
    // required DateTime dateTime,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // 🔴 1️⃣ CHECK BUSINESS RULE
      final alreadyExists = await hasActiveReservationForCar(carId);

      if (alreadyExists) {
        error = 'Cette voiture a déjà une réservation en cours.';
        notifyListeners();
        return false;
      }
      print(
          'Attempting to add reservation with clientId: $clientId, serviceId: $serviceId, carId: $carId');
      final success = await _service.addReservation(
        clientId: clientId,
        serviceId: serviceId,
        carId: carId,
        // dateTime: dateTime,
        context: context,
        clientName: clientName,
        clientPhone: clientPhone,
        serviceName: serviceName,
      );
      if (!success) {
        throw Exception(
            'Échec de l\'ajout de la réservation au niveau du service');
      }
      await loadReservations(context);
      return true;
    } catch (e) {
      print('addReservation() failed in controller: $e');
      error = 'Échec de l\'ajout de la réservation : ${e.toString()}';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReservation({
    required BuildContext context,
    required String id,
    String? status,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateReservation(
        id: id,
        status: status,
      );
      if (!success) {
        throw Exception('Échec de la mise à jour de la réservation');
      }
      await loadReservations(context);
      return true;
    } catch (e) {
      print('updateReservation() failed in controller: $e');
      error = 'Échec de la mise à jour de la réservation : ${e.toString()}';
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
