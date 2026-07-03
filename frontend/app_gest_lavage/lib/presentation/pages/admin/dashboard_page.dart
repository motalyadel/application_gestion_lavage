import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/data/services/car_service.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/data/services/service_service.dart';
import 'package:app_gest_lavage/presentation/pages/cars/add_car_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/washops_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalCars = 0;
  int _totalClients = 0;
  List<Service> _services = [];
  bool _isLoading = false;
  bool _isReservationsInitialized = false;
  late final SupabaseClient clientSpb;

  @override
  void initState() {
    super.initState();
    clientSpb = Supabase.instance.client;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Les réservations du jour servent à "Manage Cars" et au calcul du
    // revenu estimé : on réutilise le controller partagé avec les autres
    // pages admin plutôt que de refaire une requête dédiée.
    final reservationController =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isReservationsInitialized &&
        (reservationController.reservations.isEmpty ||
            reservationController.error != null)) {
      reservationController.loadReservationsJr(isAdmin: true);
      _isReservationsInitialized = true;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final authController = Provider.of<AuthController>(context, listen: false);
    final carService = CarService();

    if (authController.user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    bool isAdmin = false;
    try {
      final roleResponse = await clientSpb
          .from('user_roles')
          .select('role_id')
          .eq('user_id', authController.user!.id)
          .maybeSingle();

      if (roleResponse != null && roleResponse['role_id'] == 'admin') {
        isAdmin = true;
      }
    } catch (e) {
      debugPrint('Failed to fetch user role: $e');
    }

    try {
      final cars = await carService.getCars(isAdmin: isAdmin);
      final clients = await ClientService().getAllClients();
      final services = await ServiceService().getServices(isAdmin: true);

      if (mounted) {
        setState(() {
          _totalCars = cars.length;
          _totalClients = clients.length;
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load dashboard data failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Revenu estimé du jour = somme des prix des services pour les
  /// réservations chargées aujourd'hui.
  double _estimatedDailyRevenue(ReservationManagementController controller) {
    double total = 0;
    for (final r in controller.reservations) {
      final price = r.service?.price;
      if (price != null) total += price.toDouble();
    }
    return total;
  }

  IconData _iconForService(String name) {
    final n = name.toLowerCase();
    if (n.contains('premium') || n.contains('detail')) {
      return Icons.auto_awesome;
    }
    if (n.contains('express') || n.contains('basic')) {
      return Icons.water_drop;
    }
    return Icons.local_car_wash;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final reservationController =
        Provider.of<ReservationManagementController>(context);

    if (authController.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    final revenue = _estimatedDailyRevenue(reservationController);
    final recentReservations =
        reservationController.reservations.take(2).toList();

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            WashOpsHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy),
                    )
                  : RefreshIndicator(
                      color: WashTheme.navy,
                      onRefresh: () async {
                        await _loadDashboardData();
                        await reservationController.loadReservationsJr(
                            isAdmin: true);
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const WashSectionTitle(
                            title: 'Overview',
                            subtitle: "Today's operational metrics",
                          ),
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildRevenueCard(revenue),
                          const SizedBox(height: 28),
                          _buildManageCarsSection(recentReservations),
                          const SizedBox(height: 28),
                          _buildManageServicesSection(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // STATS
  // ---------------------------------------------------------------------

  Widget _buildStatsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_car,
            iconBg: const Color(0xFFDDEAFE),
            iconColor: const Color(0xFF2563EB),
            label: 'Total Cars',
            value: _totalCars.toString(),
            chip: const WashStatusChip(
              label: '+12%',
              background: WashTheme.chipGreenBg,
              textColor: WashTheme.chipGreenText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            iconBg: WashTheme.navy,
            iconColor: Colors.white,
            label: 'Total Clients',
            value: _totalClients.toString(),
            chip: const WashStatusChip(
              label: 'Today',
              background: WashTheme.chipGrayBg,
              textColor: WashTheme.chipGrayText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Widget chip,
  }) {
    return Container(
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
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBg,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              chip,
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: WashTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: WashTheme.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(Icons.attach_money, color: Color(0xFF15803D), size: 18),
          ),
          const SizedBox(height: 14),
          const Text(
            'Est. Daily Revenue',
            style: TextStyle(fontSize: 13, color: WashTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '\UM ${revenue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: WashTheme.navy,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MANAGE CARS (aperçu des réservations du jour)
  // ---------------------------------------------------------------------

  Widget _buildManageCarsSection(List recentReservations) {
    return Container(
      width: double.infinity,
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
              const Text(
                'Manage Cars',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: WashTheme.navy,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/cars'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WashTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (recentReservations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Aucune voiture en cours aujourd'hui",
                style: TextStyle(color: WashTheme.textSecondary),
              ),
            )
          else
            ...recentReservations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCarPreviewTile(r),
                )),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCarPage()),
                );
                if (result == true) _loadDashboardData();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add New Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WashTheme.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarPreviewTile(dynamic reservation) {
    final isInProgress = reservation.status == 'in_progress';
    final statusLabel = isInProgress
        ? (reservation.position != null
            ? 'position ${reservation.position}'
            : 'En cours')
        : 'Queued';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: WashTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WashTheme.chipGrayBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car, color: WashTheme.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reservation.car?.marque ?? ''} ${reservation.car?.modele ?? ''}'
                          .trim()
                          .isEmpty
                      ? 'Véhicule'
                      : '${reservation.car?.marque ?? ''} ${reservation.car?.modele ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'License: ${reservation.car?.immatriculation ?? '-'}',
                  style: const TextStyle(
                      fontSize: 12, color: WashTheme.textSecondary),
                ),
              ],
            ),
          ),
          WashStatusChip(
            label: statusLabel,
            background:
                isInProgress ? WashTheme.chipGreenBg : WashTheme.chipGrayBg,
            textColor:
                isInProgress ? WashTheme.chipGreenText : WashTheme.chipGrayText,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MANAGE SERVICES
  // ---------------------------------------------------------------------

  Widget _buildManageServicesSection() {
    return Container(
      width: double.infinity,
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
              const Text(
                'Manage Services',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: WashTheme.navy,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/admin/services'),
                child: const Text(
                  'Edit Catalog',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WashTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (_services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucun service configuré',
                style: TextStyle(color: WashTheme.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _services.take(2).map((s) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 32 - 12) / 2,
                  child: _buildServiceTile(s),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/admin/services'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: WashTheme.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: WashTheme.chipGrayBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings, color: WashTheme.navy),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom Service',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Variable duration',
                            style: TextStyle(
                                fontSize: 12, color: WashTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit,
                      size: 18, color: WashTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(Service service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: WashTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: WashTheme.chipGrayBg,
                child: Icon(_iconForService(service.name),
                    size: 16, color: WashTheme.navy),
              ),
              Text(
                '\UM ${service.price}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${service.duration} mins',
            style:
                const TextStyle(fontSize: 12, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
