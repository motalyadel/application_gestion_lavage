import 'package:app_gest_lavage/core/utils/app_massenger.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
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
    final reservationController =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isLoadingInitialized &&
        (reservationController.reservations.isEmpty ||
            reservationController.error != null)) {
      reservationController.loadReservationsJr(isAdmin: true);
      _isLoadingInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isAdmin = authController.currentRole == 'admin';
    final reservationController =
        Provider.of<ReservationManagementController>(context);

    if (authController.user == null || authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const WashOpsHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: WashSectionTitle(
                title: "Today's Queue",
                subtitle: 'Manage incoming and active wash sessions.',
              ),
            ),
            Expanded(
              child: reservationController.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy),
                    )
                  : reservationController.error != null &&
                          reservationController.reservations.isEmpty
                      ? _buildErrorState(reservationController.error!)
                      : reservationController.reservations.isEmpty
                          ? _buildEmptyState()
                          : _buildReservationsList(
                              reservationController, isAdmin),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/create-reservation');
          if (result == true) {
            reservationController.loadReservationsJr(isAdmin: true);
          }
        },
        backgroundColor: WashTheme.navy,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            error,
            style:
                const TextStyle(fontSize: 16, color: WashTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final reservationController =
                  Provider.of<ReservationManagementController>(context,
                      listen: false);
              reservationController.loadReservationsJr(isAdmin: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WashTheme.navy,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune réservation trouvée',
            style: TextStyle(fontSize: 18, color: WashTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Appuyez sur le bouton + pour en créer une',
            style: TextStyle(fontSize: 14, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(
      ReservationManagementController controller, bool isAdmin) {
    return RefreshIndicator(
      color: WashTheme.navy,
      onRefresh: () => controller.loadReservationsJr(isAdmin: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: controller.reservations.length,
        itemBuilder: (context, index) {
          final reservation = controller.reservations[index];
          return _buildReservationCard(reservation, controller, isAdmin);
        },
      ),
    );
  }

  Widget _buildReservationCard(
    reservation,
    ReservationManagementController controller,
    bool isAdmin,
  ) {
    final isWaiting = reservation.status == 'waiting';
    final isInProgress = reservation.status == 'in_progress';

    final statusChip = isWaiting
        ? const WashStatusChip(
            label: 'Pending',
            background: WashTheme.chipGrayBg,
            textColor: WashTheme.chipGrayText,
            icon: Icons.access_time,
          )
        : isInProgress
            ? const WashStatusChip(
                label: 'In Progress',
                background: WashTheme.chipGreenBg,
                textColor: WashTheme.chipGreenText,
                icon: Icons.directions_car,
              )
            : const WashStatusChip(
                label: 'Terminé',
                background: WashTheme.chipBlueBg,
                textColor: WashTheme.chipBlueText,
                icon: Icons.check,
              );

    final timeLabel = reservation.expectedTime != null
        ? '${reservation.expectedTime!.hour.toString().padLeft(2, '0')}:'
            '${reservation.expectedTime!.minute.toString().padLeft(2, '0')}'
        : 'En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WashTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reservation.service?.name ?? 'Service inconnu',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: WashTheme.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              statusChip,
            ],
          ),
          const SizedBox(height: 10),
          WashDetailRow(
            icon: Icons.location_on_outlined,
            value: reservation.position != null
                ? 'position ${reservation.position}'
                : 'Position non définie',
          ),
          const SizedBox(height: 6),
          WashDetailRow(
            icon: Icons.timer_outlined,
            value: timeLabel,
          ),
          const SizedBox(height: 6),
          WashDetailRow(
            icon: Icons.person_outline,
            value: reservation.car?.immatriculation ?? 'Client',
          ),
          if (isWaiting || isInProgress) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: isWaiting
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WashTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleAction(
                          reservation, controller, isAdmin, isWaiting),
                      child: const Text('Démarrer',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WashTheme.navy,
                        side: const BorderSide(color: WashTheme.navy),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleAction(
                          reservation, controller, isAdmin, isWaiting),
                      child: const Text('Terminé',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
    reservation,
    ReservationManagementController controller,
    bool isAdmin,
    bool isWaiting,
  ) async {
    final success = isWaiting
        ? await controller.startLavage(
            reservationId: reservation.id, isAdmin: isAdmin)
        : await controller.finishLavage(
            reservationId: reservation.id, isAdmin: isAdmin);

    if (success) {
      AppMessenger.showSuccess(
        isWaiting ? '🚿 Lavage démarré' : '✅ Lavage terminé',
      );
      controller.loadReservationsJr(isAdmin: true);
    } else {
      AppMessenger.showError(controller.error ?? 'Erreur');
    }
  }
}
