import 'package:app_gest_lavage/presentation/pages/admin/dashboard_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/manage_users_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/settings_page.dart';
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
    SettingsPage(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Utilisateurs'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Espace Admin")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _items,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
