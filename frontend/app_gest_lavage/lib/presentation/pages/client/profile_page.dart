import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthController().service.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // ✅ AJOUT : stub visuel — pas d'écran réel derrière ces 3 liens pour l'instant
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature : bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    if (authController.user == null || authController.currentRole != 'client') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    final user = authController.currentUser;
    // ✅ AJOUT : cast dynamique pour récupérer `photo` sans connaître le type exact
    // exposé par AuthController.currentUser (Client a ce champ, AuthModel pas forcément).
    final String? photoUrl = (user as dynamic)?.photo;
    final String name = user?.name ?? 'Client';
    final String contact = (user as dynamic)?.contact ?? 'Non spécifié';

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const WashOpsHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 8),

                  // Avatar + pencil (visuel uniquement, pas d'action liée encore)
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: WashTheme.chipGrayBg,
                          backgroundImage:
                              (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 48, color: WashTheme.navy)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () =>
                                _showComingSoon(context, 'Changer la photo'),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: WashTheme.navy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: WashTheme.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      contact,
                      style: const TextStyle(
                        fontSize: 14,
                        color: WashTheme.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Menu : visuel uniquement, pas de navigation réelle pour l'instant
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        label: 'Modifier le profil',
                        onTap: () =>
                            _showComingSoon(context, 'Modifier le profil'),
                      ),
                      const Divider(height: 1, color: WashTheme.border),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres du compte',
                        onTap: () =>
                            _showComingSoon(context, 'Paramètres du compte'),
                      ),
                      const Divider(height: 1, color: WashTheme.border),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => _showComingSoon(context, 'Notifications'),
                        showDot: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Logout — fonctionnel
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Déconnexion',
                        iconColor: Colors.red,
                        labelColor: Colors.red,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = WashTheme.navy,
    Color labelColor = Colors.black87,
    bool showDot = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor == Colors.red
                    ? Colors.red.withOpacity(0.1)
                    : WashTheme.chipBlueBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            if (showDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            const Icon(Icons.chevron_right,
                size: 20, color: WashTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
