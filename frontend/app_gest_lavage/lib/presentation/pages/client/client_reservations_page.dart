import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_colors.dart';

class ClientReservationsPage extends StatefulWidget {
  const ClientReservationsPage({super.key});

  @override
  State<ClientReservationsPage> createState() => _ClientReservationsPageState();
}

class _ClientReservationsPageState extends State<ClientReservationsPage> {
  bool _isLoadingInitialized = false;

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
    final controller =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isLoadingInitialized &&
        (controller.reservations.isEmpty || controller.error != null)) {
      controller.loadReservations(isAdmin: false);
      _isLoadingInitialized = true;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _isLoadingInitialized = false;
              reservationController.loadReservations(isAdmin: false);
            },
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
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune réservation trouvée',
                              style: TextStyle(fontSize: 18)),
                          Text('Vous n\'avez pas encore de réservation',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reservationController.reservations.length,
                      itemBuilder: (context, index) {
                        final reservation =
                            reservationController.reservations[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      reservation.service?.name ?? 'Service',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    _buildStatusChip(reservation.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  reservation.position != null
                                      ? 'Position  : ${reservation.position}'
                                      : 'Position non définie',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),

                                Text(
                                    'Véhicule : ${reservation.car?.immatriculation ?? 'Inconnu'}'),
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase(),
          style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
