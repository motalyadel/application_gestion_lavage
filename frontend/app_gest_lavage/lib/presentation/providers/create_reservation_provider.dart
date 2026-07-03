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
  String? businessHoursMessage;

  // ✅ AJOUT : pour savoir si l'utilisateur courant est admin (utilisé dans la page)
  bool isAdmin = false;

  String? selectedClientId;
  String? selectedServiceId;
  String? selectedCarId;
  Service? selectedService;

  // ✅ AJOUT : date/heure choisie pour la réservation
  DateTime? selectedDateTime;

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
    this.isAdmin = isAdmin; // ✅ AJOUT : on stocke la valeur reçue
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
      checkBusinessHours();
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

  // ✅ AJOUT : permet à la page de recharger la liste des clients
  // (ex: après avoir ajouté un nouveau client via AddClientPage)
  Future<void> reloadClients() async {
    try {
      await _loadClients();
    } catch (e) {
      error = e.toString();
    } finally {
      notifyListeners();
    }
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

  // ✅ AJOUT : setter pour la date/heure choisie dans le picker de la page
  void onDateTimeSelected(DateTime dateTime) {
    selectedDateTime = dateTime;
    notifyListeners();
  }

  // =============================
  // SUBMIT
  // =============================
  Future<bool> submit(BuildContext context) async {
    if (!canSubmit) return false;

    isSubmitting = true;
    error = null; // ✅ AJOUT : on réinitialise l'erreur à chaque tentative
    notifyListeners();

    final auth = context.read<AuthController>();
    final controller = context.read<ReservationManagementController>();
    final isAdminUser = auth.currentRole == 'admin';

    final success = await controller.addReservation(
      clientId: selectedClientId ?? auth.currentUser?.id ?? '',
      clientName: auth.currentUser?.name ?? 'admin',
      clientPhone: auth.currentUser?.contact ?? '42516535',
      serviceId: selectedServiceId!,
      serviceName: selectedService!.name,
      serviceDuration: selectedService!.duration,
      carId: selectedCarId!,
      isAdmin: isAdminUser,
    );

    // ✅ AJOUT : on récupère le vrai message d'erreur du controller
    if (!success) {
      error = controller.error ??
          'Échec de la création de la réservation. Vérifiez la connexion au serveur.';
    }

    isSubmitting = false;
    notifyListeners();

    return success;
  }

  // =============================
  // VALIDATION HEURES
  // =============================
  bool get isWithinBusinessHours {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 1 && hour < 23; // 8h00 à 22h59
  }

  void checkBusinessHours() {
    if (!isWithinBusinessHours) {
      businessHoursMessage =
          "Les réservations ne sont possibles qu'entre 08h00 et 23h00";
    } else {
      businessHoursMessage = null;
    }
    notifyListeners();
  }
}
