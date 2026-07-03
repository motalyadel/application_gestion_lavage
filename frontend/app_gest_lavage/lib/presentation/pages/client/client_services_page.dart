import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class ClientServicesPage extends StatefulWidget {
  const ClientServicesPage({super.key});

  @override
  State<ClientServicesPage> createState() => _ClientServicesPageState();
}

class _ClientServicesPageState extends State<ClientServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceManagementController>(context, listen: false)
          .loadServices(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ AJOUT : devine icône + couleur via mots-clés du nom (pas de champ catégorie en base)
  ({IconData icon, Color bg, Color fg}) _serviceVisual(String name) {
    final n = name.toLowerCase();
    if (n.contains('ceramic') || n.contains('céramique')) {
      return (icon: Icons.shield, bg: WashTheme.navy, fg: Colors.white);
    }
    if (n.contains('premium') || n.contains('ultimate') || n.contains('detail')) {
      return (
        icon: Icons.auto_awesome,
        bg: WashTheme.chipBlueBg,
        fg: WashTheme.chipBlueText
      );
    }
    if (n.contains('oil') || n.contains('huile') || n.contains('filtre')) {
      return (icon: Icons.build, bg: const Color(0xFF1B4332), fg: Colors.white);
    }
    if (n.contains('interior') || n.contains('intérieur') ||
        n.contains('sanitiz')) {
      return (
        icon: Icons.cleaning_services,
        bg: WashTheme.chipGrayBg,
        fg: WashTheme.chipGrayText
      );
    }
    // Express / défaut
    return (
      icon: Icons.local_car_wash,
      bg: WashTheme.navy,
      fg: Colors.white,
    );
  }

  List<Service> _filteredServices(List<Service> all) {
    if (_searchQuery.trim().isEmpty) return all;
    final query = _searchQuery.trim().toLowerCase();
    return all.where((s) => s.name.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final serviceController = Provider.of<ServiceManagementController>(context);

    if (authController.user == null || authController.currentRole != 'client') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    final services = _filteredServices(serviceController.services);

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
              child: serviceController.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy))
                  : serviceController.error != null
                      ? Center(child: Text(serviceController.error!))
                      : RefreshIndicator(
                          onRefresh: () =>
                              serviceController.loadServices(context),
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              _buildHeroBanner(),
                              const SizedBox(height: 18),
                              _buildSearchBar(),
                              const SizedBox(height: 18),
                              if (services.isEmpty)
                                _buildEmptyState()
                              else
                                ...services
                                    .map((s) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _buildServiceCard(s),
                                        ))
                                    .toList(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1B3D), Color(0xFF1E3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Premium Care',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Découvrez le meilleur de l\'entretien et du detailing automobile.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
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
                hintText: 'Rechercher un service...',
                hintStyle: TextStyle(color: WashTheme.textSecondary),
                prefixIcon:
                    Icon(Icons.search, color: WashTheme.textSecondary),
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
      child: const Column(
        children: [
          Icon(Icons.build_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun service trouvé',
            style: TextStyle(fontSize: 16, color: WashTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    final visual = _serviceVisual(service.name);

    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: visual.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, color: visual.fg, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WashTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: WashTheme.textSecondary, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                WashStatusChip(
                  label: '${service.price} UM • ${service.duration} mins',
                  background: WashTheme.chipGreenBg,
                  textColor: WashTheme.chipGreenText,
                ),
                if (service.description != null &&
                    service.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    service.description!,
                    style: const TextStyle(
                        fontSize: 13, color: WashTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}