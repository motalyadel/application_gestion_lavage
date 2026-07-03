import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class ClientReservationsPage extends StatefulWidget {
  const ClientReservationsPage({super.key});

  @override
  State<ClientReservationsPage> createState() => _ClientReservationsPageState();
}

class _ClientReservationsPageState extends State<ClientReservationsPage> {
  bool _isLoadingInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReservationsIfNeeded() {
    final controller =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isLoadingInitialized &&
        (controller.reservations.isEmpty || controller.error != null)) {
      controller.loadReservationsJr(isAdmin: false);
      _isLoadingInitialized = true;
    }
  }

  // ✅ AJOUT : même logique de calcul de % que dans AccueilPage
  double _calculateProgress(Reservation r) {
    final duration = r.service?.duration;
    if (r.startedAt == null || duration == null || duration <= 0) return 0;
    final elapsedMinutes = DateTime.now().difference(r.startedAt!).inMinutes;
    final percent = (elapsedMinutes / duration) * 100;
    return percent.clamp(0, 100).toDouble();
  }

  // ✅ AJOUT : filtre local par plaque d'immatriculation
  List<Reservation> _filteredReservations(List<Reservation> all) {
    if (_searchQuery.trim().isEmpty) return all;
    final query = _searchQuery.trim().toLowerCase();
    return all
        .where(
            (r) => (r.car?.immatriculation ?? '').toLowerCase().contains(query))
        .toList();
  }

  // ✅ AJOUT : mapping statut réel -> libellé + couleurs d'affichage
  ({String label, Color bg, Color text}) _statusStyle(String status) {
    switch (status) {
      case 'waiting':
        return (
          label: 'En attente',
          bg: WashTheme.chipBlueBg,
          text: WashTheme.chipBlueText
        );
      case 'in_progress':
        return (
          label: 'En cours',
          bg: WashTheme.chipGreenBg,
          text: WashTheme.chipGreenText
        );
      default:
        return (
          label: 'Terminé',
          bg: WashTheme.chipGrayBg,
          text: WashTheme.chipGrayText
        );
    }
  }

  String _shortRef(String id) {
    final clean = id.replaceAll('-', '');
    return '#WASH-${clean.substring(0, clean.length >= 6 ? 6 : clean.length).toUpperCase()}';
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

    final reservations =
        _filteredReservations(reservationController.reservations);

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
                  _isLoadingInitialized = false;
                  await reservationController.loadReservationsJr(
                      isAdmin: false);
                },
                child: reservationController.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: WashTheme.navy))
                    : reservationController.error != null &&
                            reservationController.reservations.isEmpty
                        ? Center(child: Text(reservationController.error!))
                        : ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              const WashSectionTitle(
                                title: 'Mes Réservations',
                                subtitle:
                                    'Suivez et gérez vos services de nettoyage en temps réel.',
                              ),
                              const SizedBox(height: 18),
                              _buildSearchBar(),
                              const SizedBox(height: 18),
                              if (reservations.isEmpty)
                                _buildEmptyState()
                              else
                                ...reservations
                                    .map((r) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: _buildReservationCard(r),
                                        ))
                                    .toList(),
                              const SizedBox(height: 8),
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
          if (result == true) {
            reservationController.loadReservationsJr(isAdmin: false);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: WashTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WashTheme.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher par plaque...',
                hintStyle: TextStyle(color: WashTheme.textSecondary),
                prefixIcon: Icon(Icons.search, color: WashTheme.textSecondary),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WashTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WashTheme.border),
          ),
          child: const Icon(Icons.tune, color: WashTheme.navy, size: 20),
        ),
      ],
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
            'Aucune réservation trouvée',
            style: TextStyle(fontSize: 16, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation r) {
    final style = _statusStyle(r.status);
    final progress = r.status == 'in_progress' ? _calculateProgress(r) : null;

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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.local_car_wash,
                        color: WashTheme.navy, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.service?.name ?? 'Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WashTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              WashStatusChip(
                label: style.label,
                background: style.bg,
                textColor: style.text,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'REF ${_shortRef(r.id)}',
            style:
                const TextStyle(fontSize: 12, color: WashTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn(
                  'Véhicule',
                  r.car?.immatriculation ?? 'Inconnu',
                ),
              ),
              Expanded(
                child: _buildInfoColumn(
                  'Position',
                  r.position != null ? 'position ${r.position}' : 'Non définie',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoColumn(
            'Heure',
            r.expectedTime != null
                ? '${r.expectedTime!.hour.toString().padLeft(2, '0')}:${r.expectedTime!.minute.toString().padLeft(2, '0')}'
                : 'En attente',
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression du nettoyage',
                  style:
                      TextStyle(fontSize: 12, color: WashTheme.textSecondary),
                ),
                Text(
                  '${progress.toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WashTheme.navy,
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
                    const AlwaysStoppedAnimation(WashTheme.chipGreenText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: WashTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
