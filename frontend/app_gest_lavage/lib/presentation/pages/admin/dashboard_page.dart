import 'package:app_gest_lavage/data/services/car_service.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/pages/cars/add_car_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/admin_services_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_colors.dart';



class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalCars = 0;
  int _totalClients = 0;
  bool _isLoading = false;
  late final SupabaseClient clientSpb;

  @override
  void initState() {
    super.initState();
    clientSpb = Supabase.instance.client;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
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
      print('Failed to fetch user role: $e');
    }

    try {
      final cars = await carService.getCars(isAdmin: isAdmin);
      final clients = await ClientService().getAllClients();

      if (mounted) {
        setState(() {
          _totalCars = cars.length;
          _totalClients = clients.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load dashboard data failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    if (authController.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // AppBar moderne
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Tableau de Bord',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDashboardData,
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome
                        Text(
                          'Bienvenue, ${authController.currentUser?.name ?? 'Admin'} 👋',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Gérez votre laverie auto efficacement',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Stats Cards
                        const Text(
                          'Résumé',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildModernStatCard(
                                icon: Icons.directions_car,
                                label: 'Total Voitures',
                                value: _totalCars.toString(),
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernStatCard(
                                icon: Icons.people,
                                label: 'Clients Actifs',
                                value: _totalClients.toString(),
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Action Cards
                        _buildActionCard(
                          title: 'Ajouter une Voiture',
                          subtitle: 'Enregistrer un nouveau véhicule',
                          icon: Icons.add_circle,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddCarPage()),
                            );
                            if (result == true) _loadDashboardData();
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildActionCard(
                          title: 'Gérer les Voitures',
                          subtitle: 'Voir et gérer la liste des véhicules',
                          icon: Icons.directions_car,
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, '/cars');
                            if (result == true) _loadDashboardData();
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildActionCard(
                          title: 'Gérer les Services',
                          subtitle: 'Configurer les services de lavage',
                          icon: Icons.build,
                          onTap: () => Navigator.pushNamed(context, '/admin/services'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}