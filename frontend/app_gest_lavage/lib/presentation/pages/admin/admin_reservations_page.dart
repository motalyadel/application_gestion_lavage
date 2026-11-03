import 'package:app_gest_lavage/data/models/reservation_model.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final controller =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isLoadingInitialized) {
      controller.loadReservationsJr(isAdmin: true);
      _isLoadingInitialized = true;
    }
  }

  // ✅ Calcul progression lavage en cours (started_at + durée service)
  double _calculateProgress(Reservation r) {
    final duration = r.service?.duration;
    if (r.startedAt == null || duration == null || duration <= 0) return 0;
    final elapsed = DateTime.now().difference(r.startedAt!).inMinutes;
    return (elapsed / duration * 100).clamp(0, 100).toDouble();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final controller = Provider.of<ReservationManagementController>(context);

    if (authController.user == null || authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    // Stats rapides
    final inProgress =
        controller.reservations.where((r) => r.status == 'in_progress').length;
    final waiting =
        controller.reservations.where((r) => r.status == 'waiting').length;

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const WashOpsHeader(),
            Expanded(
              child: controller.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy))
                  : controller.error != null &&
                          controller.reservations.isEmpty
                      ? _buildErrorState(controller)
                      : RefreshIndicator(
                          onRefresh: () async {
                            _isLoadingInitialized = false;
                            await controller.loadReservationsJr(isAdmin: true);
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            children: [
                              // ── Titre + refresh ──────────────────────────
                              Row(
                                children: [
                                  const Expanded(
                                    child: WashSectionTitle(
                                      title: 'Réservations du jour',
                                      subtitle:
                                          'Gérez les lavages en temps réel.',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: WashTheme.navy),
                                    onPressed: () {
                                      _isLoadingInitialized = false;
                                      controller.loadReservationsJr(
                                          isAdmin: true);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Stats rapides ────────────────────────────
                              Row(
                                children: [
                                  _buildStatChip(
                                    label: '$inProgress En cours',
                                    bg: WashTheme.chipBlueBg,
                                    textColor: WashTheme.chipBlueText,
                                    icon: Icons.local_car_wash,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildStatChip(
                                    label: '$waiting En attente',
                                    bg: WashTheme.chipOrangeBg,
                                    textColor: WashTheme.chipOrangeText,
                                    icon: Icons.schedule,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ── Liste ────────────────────────────────────
                              if (controller.reservations.isEmpty)
                                _buildEmptyState()
                              else
                                ...controller.reservations.map((r) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: _buildReservationCard(
                                          r, controller),
                                    )),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WashTheme.navy,
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/create-reservation');
          if (result == true && mounted) {
            _isLoadingInitialized = false;
            controller.loadReservationsJr(isAdmin: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildReservationCard(
    Reservation r, ReservationManagementController controller) {
  final progress =
      r.status == 'in_progress' ? _calculateProgress(r) : null;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WashTheme.cardBackground,
      borderRadius: BorderRadius.circular(WashTheme.radiusCard),
      border: Border.all(
        color: r.status == 'in_progress'
            ? WashTheme.chipBlueText.withOpacity(0.3)
            : WashTheme.border,
        width: r.status == 'in_progress' ? 1.5 : 1,
      ),
      boxShadow: WashTheme.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header : service + statut ───────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: r.status == 'in_progress'
                    ? WashTheme.chipBlueBg
                    : WashTheme.chipGrayBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                r.status == 'in_progress'
                    ? Icons.local_car_wash
                    : Icons.schedule,
                color: r.status == 'in_progress'
                    ? WashTheme.chipBlueText
                    : WashTheme.chipGrayText,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.service?.name ?? 'Service inconnu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: WashTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  WashStatusChip.fromStatus(r.status),
                ],
              ),
            ),
            // ── Badge machine ───────────────────────────────────────
            if (r.machineId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: WashTheme.navy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Bay ${r.machineId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: WashTheme.border),
        const SizedBox(height: 12),

        // ── Infos en grille 2×2 ─────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _infoCell(
                icon: Icons.confirmation_number_outlined,
                label: 'Position',
                value: r.position != null ? '#${r.position}' : 'N/A',
              ),
            ),
            Expanded(
              child: _infoCell(
                icon: Icons.directions_car_outlined,
                label: 'Véhicule',
                value: r.car?.immatriculation ?? 'Inconnu',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _infoCell(
                icon: Icons.access_time,
                label: 'Heure estimée',
                value: _formatTime(r.expectedTime),
              ),
            ),
            Expanded(
              child: _infoCell(
                icon: Icons.timer_outlined,
                label: 'Durée',
                value: r.service?.duration != null
                    ? '${r.service!.duration} min'
                    : 'N/A',
              ),
            ),
          ],
        ),

        // ── Barre de progression (in_progress seulement) ────────────
        if (progress != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progression',
                  style: TextStyle(
                      fontSize: 12, color: WashTheme.textSecondary)),
              Text(
                '${progress.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: WashTheme.chipBlueText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: WashTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation(WashTheme.chipBlueText),
            ),
          ),
        ],

        // ── Bouton Démarrer / Terminer ───────────────────────────────
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(
              r.status == 'waiting'
                  ? Icons.play_arrow
                  : Icons.check_circle,
              size: 18,
            ),
            label: Text(
              r.status == 'waiting'
                  ? 'Démarrer le lavage'
                  : 'Terminer le lavage',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: r.status == 'waiting'
                  ? WashTheme.navy
                  : WashTheme.actionSuccess,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(WashTheme.radiusButton),
              ),
            ),
            onPressed: controller.loading
                ? null
                : () async {
                    final bool success;
                    if (r.status == 'waiting') {
                      success = await controller.startLavage(
                        reservationId: r.id,
                        isAdmin: true,
                      );
                    } else {
                      success = await controller.finishLavage(
                        reservationId: r.id,
                        isAdmin: true,
                      );
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? r.status == 'waiting'
                                  ? '🚿 Lavage démarré'
                                  : '✅ Lavage terminé'
                              : controller.error ?? 'Erreur'),
                          backgroundColor: success
                              ? WashTheme.actionSuccess
                              : WashTheme.actionDanger,
                        ),
                      );
                    }
                  },
          ),
        ),

        // ── Bouton Annuler (waiting uniquement) ─────────────────────
        if (r.status == 'waiting') ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text(
                'Annuler la réservation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: WashTheme.actionDanger,
                side: const BorderSide(color: WashTheme.actionDanger),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(WashTheme.radiusButton),
                ),
              ),
              onPressed: controller.loading
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Annuler la réservation ?'),
                          content: Text(
                            'Le lavage "${r.service?.name ?? 'Service'}" '
                            '(${r.car?.immatriculation ?? 'Véhicule'}) '
                            'sera annulé définitivement.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Garder',
                                  style: TextStyle(
                                      color: WashTheme.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Annuler',
                                  style: TextStyle(
                                    color: WashTheme.actionDanger,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      final success = await controller.cancelReservation(
                        reservationId: r.id,
                        isAdmin: true,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? '🚫 Réservation annulée'
                                : controller.error ??
                                    'Erreur d\'annulation'),
                            backgroundColor: success
                                ? WashTheme.chipGrayText
                                : WashTheme.actionDanger,
                          ),
                        );
                      }
                    },
            ),
          ),
        ],
      ],
    ),
  );
}

  // ── WIDGETS HELPERS ───────────────────────────────────────────────────────

  Widget _infoCell({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: WashTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: WashTheme.textSecondary)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WashTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required Color bg,
    required Color textColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune réservation active aujourd\'hui',
            style: TextStyle(fontSize: 16, color: WashTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Appuyez sur + pour en créer une',
            style: TextStyle(fontSize: 13, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReservationManagementController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: WashTheme.actionDanger),
            const SizedBox(height: 16),
            Text(
              controller.error!,
              style: const TextStyle(
                  fontSize: 14, color: WashTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _isLoadingInitialized = false;
                controller.loadReservationsJr(isAdmin: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WashTheme.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}