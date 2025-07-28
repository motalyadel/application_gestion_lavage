import 'package:app_gest_lavage/presentation/pages/client/accueil_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/profile_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/reservations_page.dart';
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
    ReservationsPage(),
    ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Réservations'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Espace Client")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _items,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}