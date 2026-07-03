import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/data/services/car_service.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  int _totalCars = 0;
  bool _isLoading = false;
  bool _isLoadingReservation = false;
  Reservation? _activeReservation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadActiveReservation();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authController = Provider.of<AuthController>(context, listen: false);
    final carService = CarService();

    try {
      final cars = await carService.getCars(
          isAdmin: authController.currentRole == 'admin');
      if (mounted) {
        setState(() {
          _totalCars = cars.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e')),
        );
      }
    }
  }

  // ✅ AJOUT : récupère la réservation "in_progress" du client, s'il y en a une
  Future<void> _loadActiveReservation() async {
    setState(() => _isLoadingReservation = true);
    final reservationController =
        Provider.of<ReservationManagementController>(context, listen: false);

    try {
      await reservationController.loadReservationsJr(isAdmin: false);
      final inProgress = reservationController.reservations
          .where((r) => r.status == 'in_progress')
          .toList();
      if (mounted) {
        setState(() {
          _activeReservation = inProgress.isNotEmpty ? inProgress.first : null;
          _isLoadingReservation = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReservation = false);
    }
  }

  // ✅ AJOUT : calcule le % de progression à partir de started_at + durée du service
  double _calculateProgress(Reservation r) {
    final duration = r.service?.duration;
    if (r.startedAt == null || duration == null || duration <= 0) return 0;
    final elapsedMinutes = DateTime.now().difference(r.startedAt!).inMinutes;
    final percent = (elapsedMinutes / duration) * 100;
    return percent.clamp(0, 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    if (authController.currentRole == null ||
        authController.currentUser == null) {
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
            WashOpsHeader(
              onAvatarTap: () => Navigator.pushNamed(context, '/profile'),
              onNotificationTap: () {},
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadData();
                  await _loadActiveReservation();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Bonjour, ${authController.currentUser!.name ?? 'Client'} 👋',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: WashTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Prêt pour une voiture étincelante aujourd\'hui ?',
                      style: TextStyle(fontSize: 14, color: WashTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // ✅ CTA principal
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create-reservation'),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Réserver un lavage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WashTheme.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stat card : voitures enregistrées
                    _buildStatCard(),

                    const SizedBox(height: 16),

                    // ✅ Carte "Lavage en cours" (uniquement si réservation in_progress)
                    if (_isLoadingReservation)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                            child: CircularProgressIndicator(color: WashTheme.navy)),
                      )
                    else if (_activeReservation != null)
                      _buildActiveWashCard(_activeReservation!),

                    if (_activeReservation != null) const SizedBox(height: 20),
                    if (_activeReservation == null && !_isLoadingReservation)
                      const SizedBox(height: 4),

                    // Action cards
                    _buildPrimaryActionCard(
                      title: 'Gérer Mes Voitures',
                      subtitle: 'Mettre à jour vos véhicules ou en ajouter un.',
                      ctaLabel: 'VOIR LES VÉHICULES',
                      icon: Icons.settings_suggest_outlined,
                      onTap: () => Navigator.pushNamed(context, '/cars'),
                    ),
                    const SizedBox(height: 14),
                    _buildSecondaryActionCard(
                      title: 'Nos Services',
                      subtitle: 'Découvrez nos formules de lavage et détailing.',
                      ctaLabel: 'VOIR LE MENU',
                      icon: Icons.local_car_wash_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, '/client/services'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WashTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: WashTheme.chipBlueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car,
                color: WashTheme.chipBlueText, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? '...' : '$_totalCars Voiture${_totalCars > 1 ? 's' : ''} enregistrée${_totalCars > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: WashTheme.navy,
                  ),
                ),
                const Text(
                  'Gérez votre flotte en un seul endroit',
                  style: TextStyle(fontSize: 12, color: WashTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWashCard(Reservation r) {
    final progress = _calculateProgress(r);
    final carLabel = r.car != null
        ? '${r.car!.marque ?? ''} ${r.car!.modele ?? ''} (${r.car!.immatriculation})'.trim()
        : 'Véhicule inconnu';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WashTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
              const WashStatusChip(
                label: 'EN COURS',
                background: WashTheme.chipGreenBg,
                textColor: WashTheme.chipGreenText,
              ),
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 4,
                      backgroundColor: WashTheme.border,
                      valueColor: const AlwaysStoppedAnimation(
                          WashTheme.chipGreenText),
                    ),
                    Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: WashTheme.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.service?.name ?? 'Service',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: WashTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          WashDetailRow(icon: Icons.directions_car_filled, value: carLabel),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionCard({
    required String title,
    required String subtitle,
    required String ctaLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WashTheme.navy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required String title,
    required String subtitle,
    required String ctaLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WashTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WashTheme.navy, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: WashTheme.navy, size: 22),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: WashTheme.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: WashTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WashTheme.navy,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14, color: WashTheme.navy),
              ],
            ),
          ],
        ),
      ),
    );
  }
}