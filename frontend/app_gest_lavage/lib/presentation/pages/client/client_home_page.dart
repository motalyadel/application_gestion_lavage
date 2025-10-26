import 'package:app_gest_lavage/presentation/pages/client/accueil_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/client_reservations_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/profile_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/reservations_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AccueilPage(),
    // ReservationsPage(),
    const ClientReservationsPage(),
    ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
    BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today), label: 'Réservations'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
  ];

  void _logout(BuildContext context) async {
    await AuthController().service.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Client"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _logout(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Déconnexion'),
              ),
            ],
            icon: const Icon(Icons.account_circle),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _items,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
