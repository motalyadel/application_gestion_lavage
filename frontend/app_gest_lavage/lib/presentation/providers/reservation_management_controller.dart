import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/data/services/reservation_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/data/services/reservation_service.dart';
import 'package:flutter/material.dart';

class ReservationManagementController extends ChangeNotifier {
  final ReservationService _service = ReservationService();
  final SupabaseClient clientSpb = Supabase.instance.client;

  List<Reservation> reservations = [];
  bool loading = false;
  String? error;

  /// 🔹 Charger les réservations pour admin ou client
  Future<void> loadReservations({required bool isAdmin}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      reservations = await _service.getReservations(isAdmin: isAdmin);
    } catch (e) {
      print('loadReservations() failed: $e');
      error = 'Échec du chargement des réservations';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 🔹 Démarrer le lavage
  Future<bool> startLavage({
    required String reservationId,
    required bool isAdmin, // pour recharger correctement les réservations
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.startLavage(reservationId: reservationId);

      if (!success) {
        throw Exception('n8n a refusé le démarrage du lavage');
      }

      // Recharge les réservations après démarrage
      await loadReservations(isAdmin: isAdmin);
      return true;
    } catch (e) {
      print('startLavage() failed: $e');
      error = 'Échec du démarrage du lavage';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 🔹 Terminer le lavage (Version finale propre)
  Future<bool> finishLavage({
    required String reservationId,
    required bool isAdmin,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      print('🔄 [finishLavage] Début - Reservation ID: $reservationId');

      // Appel à ton endpoint n8n
      final success = await _service.finishLavage(reservationId: reservationId);

      if (!success) {
        throw Exception('n8n a refusé la finalisation du lavage');
      }

      print('✅ [finishLavage] Succès via n8n');

      // Recharge les données pour rafraîchir l'UI
      await loadReservations(isAdmin: isAdmin);

      return true;
    } catch (e) {
      print('❌ [finishLavage] Erreur: $e');
      error = 'Échec de la finalisation du lavage';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 🔹 Ajouter une réservation
  Future<bool> addReservation({
    required String clientId,
    required String clientName,
    required String clientPhone,
    required String serviceId,
    required String serviceName,
    required int serviceDuration,
    required String carId,
    required bool isAdmin, // pour recharger correctement les réservations
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.addReservation(
        clientId: clientId,
        clientName: clientName,
        clientPhone: clientPhone,
        serviceId: serviceId,
        serviceName: serviceName,
        // serviceDuration: serviceDuration, // si tu veux l'utiliser plus tard
        carId: carId,
      );

      if (!success) {
        throw Exception('Échec de l\'ajout de la réservation');
      }

      // Recharge toutes les réservations après ajout
      await loadReservations(isAdmin: isAdmin);
      return true;
    } catch (e) {
      print('addReservation() failed: $e');
      error = 'Échec de l’ajout de la réservation';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
