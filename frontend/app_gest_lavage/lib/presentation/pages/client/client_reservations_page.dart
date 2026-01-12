import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 25, 118, 210);
  static const Color primaryDark = Color.fromARGB(255, 13, 71, 161);
  static const Color primaryLight = Color.fromARGB(255, 187, 222, 251);
  static const Color secondary = Color.fromARGB(255, 67, 160, 71);
  static const Color accent = Color.fromARGB(255, 251, 140, 0);
  static const Color error = Color.fromARGB(255, 229, 57, 53);
  static const Color background = Color.fromARGB(255, 245, 245, 245);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);
  static const Color textPrimary = Color.fromARGB(255, 67, 37, 37);
  static const Color textSecondary = Color.fromARGB(255, 117, 117, 117);
}

class ClientReservationsPage extends StatefulWidget {
  const ClientReservationsPage({super.key});

  @override
  State<ClientReservationsPage> createState() => _ClientReservationsPageState();
}

class _ClientReservationsPageState extends State<ClientReservationsPage> {
  bool _isLoadingInitialized = false; // Flag to prevent multiple initial loads

  @override
  void initState() {
    super.initState();
    _loadReservationsIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReservationsIfNeeded();
  }

  void _loadReservationsIfNeeded() {
    final reservationController =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isLoadingInitialized &&
        (reservationController.reservations.isEmpty ||
            reservationController.error != null)) {
      reservationController.loadReservations(isAdmin: false);
      _isLoadingInitialized = true; // Set flag after first load
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final reservationController =
        Provider.of<ReservationManagementController>(context);

    if (authController.user == null || authController.currentRole != 'client') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _isLoadingInitialized = false; // Reset flag on manual refresh
              reservationController.loadReservations(isAdmin: false);
            },
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: reservationController.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : reservationController.error != null &&
                  reservationController.reservations.isEmpty
              ? Center(child: Text(reservationController.error!))
              : reservationController.reservations.isEmpty
                  ? const Center(child: Text('Aucune réservation trouvée'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reservationController.reservations.length,
                      itemBuilder: (context, index) {
                        final reservation =
                            reservationController.reservations[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today,
                                color: AppColors.primary),
                            title: Text(
                              reservation.service?.name ?? 'Service inconnu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),

                                // 🚗 Immatriculation
                                Text(
                                  reservation.car?.immatriculation != null
                                      ? 'Véhicule : ${reservation.car!.immatriculation}'
                                      : 'Véhicule : inconnu',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Position
                                Text(
                                  reservation.position != null
                                      ? 'Position  : ${reservation.position}'
                                      : 'Position non définie',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),

                                const SizedBox(height: 4),

                                // Expected time
                                Text(
                                  reservation.expectedTime != null
                                      ? 'Heure estimée : '
                                          '${reservation.expectedTime!.hour.toString().padLeft(2, '0')}:'
                                          '${reservation.expectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Heure estimée : en attente',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),

                                const SizedBox(height: 4),

                                // Status
                                Text(
                                  'Statut : ${reservation.status}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: reservation.status == 'waiting'
                                        ? Colors.orange
                                        : reservation.status == 'in_progress'
                                            ? Colors.blue
                                            : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/create-reservation');
          if (result == true) {
            reservationController.loadReservations(isAdmin: false);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
