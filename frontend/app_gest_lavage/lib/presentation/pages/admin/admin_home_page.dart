import 'package:app_gest_lavage/presentation/pages/admin/admin_reservations_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/dashboard_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/manage_users_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/settings_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    ManageUsersPage(),
    // SettingsPage(),
    AdminReservationsPage()
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Utilisateurs'),
    // BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
    BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today), label: 'reservations'),
  ];

  void _logout(BuildContext context) async {
    await AuthController().service.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Admin"),
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
