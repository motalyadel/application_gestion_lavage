import 'package:app_gest_lavage/presentation/pages/admin/admin_reservations_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/dashboard_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/manage_users_page.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_colors.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ManageUsersPage(),
    AdminReservationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ❌ Plus d'AppBar globale : chaque page gère son propre WashOpsHeader
      // ✅ La déconnexion est gérée par défaut via l'avatar du WashOpsHeader
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Utilisateurs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Réservations',
            ),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
