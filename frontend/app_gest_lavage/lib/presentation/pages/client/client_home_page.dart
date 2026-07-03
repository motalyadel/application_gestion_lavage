import 'package:app_gest_lavage/presentation/pages/client/accueil_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/client_reservations_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/profile_page.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_colors.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AccueilPage(),
    const ClientReservationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❌ Plus d'AppBar globale : chaque page gère son propre WashOpsHeader
      // ✅ La déconnexion sera gérée dans ProfilePage (bouton Logout, cf. design Stitch)
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'Réservations'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
