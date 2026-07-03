// lib/core/widgets/washops_header.dart

import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';

class WashTheme {
  static const Color navy = Color(0xFF0E1B3D);
  static const Color navyDark = Color(0xFF0A1330);
  static const Color background = Color(0xFFF6F7FB);
  static const Color cardBackground = Colors.white;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color chipBlueBg = Color(0xFFE0EAFE);
  static const Color chipBlueText = Color(0xFF1D4ED8);
  static const Color chipGreenBg = Color(0xFFDCFCE7);
  static const Color chipGreenText = Color(0xFF15803D);
  static const Color chipGrayBg = Color(0xFFE9ECF2);
  static const Color chipGrayText = Color(0xFF4B5563);
  static const Color chipOrangeBg = Color(0xFFFEF3C7);
  static const Color chipOrangeText = Color(0xFFB45309);
}

class WashOpsHeader extends StatelessWidget {
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final bool hasNotification;
  final bool showBackButton;

  const WashOpsHeader({
    super.key,
    this.onAvatarTap,
    this.onNotificationTap,
    this.hasNotification = true,
    this.showBackButton = true,
  });

  // ✅ AJOUT : comportement par défaut de l'avatar = déconnexion (avec confirmation)
  // Utilisé uniquement quand `onAvatarTap` n'est pas fourni (typiquement les
  // pages admin, qui n'ont pas de page Profil dédiée).
  Future<void> _handleAvatarTap(BuildContext context) async {
    if (onAvatarTap != null) {
      onAvatarTap!();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: WashTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthController().service.signOut();
      if (context.mounted) {
        // ✅ AJOUT : on vide toute la pile de navigation pour éviter de
        // pouvoir "revenir" sur des pages authentifiées après déconnexion.
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton && Navigator.canPop(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WashTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          canGoBack
              ? GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child:
                        Icon(Icons.arrow_back, color: WashTheme.navy, size: 22),
                  ),
                )
              : GestureDetector(
                  onTap: () => _handleAvatarTap(context), // ✅ MODIFIÉ
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: WashTheme.chipGrayBg,
                    child: Icon(Icons.person, color: WashTheme.navy, size: 20),
                  ),
                ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'WashOps Pro',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: WashTheme.navy,
              ),
            ),
          ),
          GestureDetector(
            onTap: onNotificationTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 26, color: WashTheme.navy),
                  if (hasNotification)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête de section : grand titre + sous-titre.
class WashSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const WashSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: WashTheme.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: WashTheme.textSecondary),
        ),
      ],
    );
  }
}

/// Petit badge "pill" pour les statuts.
class WashStatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final IconData? icon;

  const WashStatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de détail "icône + valeur" utilisée dans les cartes.
class WashDetailRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const WashDetailRow({super.key, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: WashTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
