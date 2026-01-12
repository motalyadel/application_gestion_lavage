import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/data/models/service_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateReservationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =============================
  // STATE
  // =============================
  bool isLoading = false;
  bool isSubmitting = false;
  String? error;

  String? selectedClientId;
  String? selectedServiceId;
  String? selectedCarId;
  Service? selectedService;

  List<Map<String, dynamic>> clients = [];
  List<Service> services = [];
  List<Car> cars = [];

  /// voitures déjà réservées (status != done)
  Set<String> busyCarIds = {};

  // =============================
  // INIT
  // =============================
  Future<void> init({
    required bool isAdmin,
    required String? userId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadServices(),
        _loadBusyCars(),
      ]);

      if (isAdmin) {
        await _loadClients();
      } else {
        selectedClientId = userId;
        await loadCarsForClient(userId);
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // =============================
  // LOADERS
  // =============================
  Future<void> _loadServices() async {
    final res = await _supabase.from('services').select();
    services = res.map<Service>((e) => Service.fromMap(e)).toList();
  }

  Future<void> _loadClients() async {
    final res =
        await _supabase.from('users').select('id, name').eq('status', 'Active');

    clients = List<Map<String, dynamic>>.from(res);
  }

  /// voitures du client sélectionné
  Future<void> loadCarsForClient(String? clientId) async {
    if (clientId == null) {
      cars = [];
      selectedCarId = null;
      notifyListeners();
      return;
    }

    final res = await _supabase
        .from('cars')
        .select(
            'id, user_id, marque, modele, immatriculation, created_at, updated_at')
        .eq('user_id', clientId);

    cars = res.map<Car>((e) => Car.fromMap(e)).toList();

    selectedCarId = null;
    notifyListeners();
  }

  /// voitures déjà en réservation
  Future<void> _loadBusyCars() async {
    final res = await _supabase
        .from('reservations')
        .select('car_id')
        .neq('status', 'done');

    busyCarIds = res.map<String>((e) => e['car_id'] as String).toSet();
  }

  // =============================
  // HELPERS
  // =============================
  bool isCarBusy(String carId) => busyCarIds.contains(carId);

  bool get canSubmit =>
      selectedClientId != null &&
      selectedServiceId != null &&
      selectedCarId != null &&
      !isSubmitting &&
      !isCarBusy(selectedCarId!);

  List<Car> get availableCars => cars;

  // =============================
  // SETTERS (UI)
  // =============================
  void onClientSelected(String? clientId) {
    selectedClientId = clientId;
    selectedCarId = null;
    cars = [];
    notifyListeners();
    loadCarsForClient(clientId);
  }

  void onServiceSelected(String? serviceId) {
    selectedServiceId = serviceId;
    selectedService = services.firstWhere((s) => s.id == serviceId);
    notifyListeners();
  }

  void onCarSelected(String? carId) {
    if (carId != null && isCarBusy(carId)) return;
    selectedCarId = carId;
    notifyListeners();
  }

  // =============================
  // SUBMIT
  // =============================
  Future<bool> submit(BuildContext context) async {
  if (!canSubmit) return false;

  isSubmitting = true;
  notifyListeners();

  final auth = context.read<AuthController>();
  final controller = context.read<ReservationManagementController>();

  // Déterminer si l'utilisateur est admin
  final isAdmin = auth.currentRole == 'admin';

  // 🔹 Appel de addReservation sans passer context
  final success = await controller.addReservation(
    clientId: selectedClientId ?? auth.currentUser?.id ?? '',
    clientName: auth.currentUser?.name ?? 'admin',
    clientPhone: auth.currentUser?.contact ?? '42516535',
    serviceId: selectedServiceId!,
    serviceName: selectedService!.name,
    serviceDuration: selectedService!.duration,
    carId: selectedCarId!,
    isAdmin: isAdmin, // Pour recharger correctement les reservations
  );

  isSubmitting = false;
  notifyListeners();

  return success;
}

}
