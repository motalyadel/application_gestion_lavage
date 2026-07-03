// import 'dart:ui';

// class AppColors {
//   static const Color primary = Color.fromARGB(255, 25, 118, 210);
//   static const Color primaryDark = Color.fromARGB(255, 13, 71, 161);
//   static const Color primaryLight = Color.fromARGB(255, 187, 222, 251);
//   static const Color secondary = Color.fromARGB(255, 67, 160, 71);
//   static const Color accent = Color.fromARGB(255, 251, 140, 0);
//   static const Color error = Color.fromARGB(255, 229, 57, 53);
//   static const Color background = Color.fromARGB(255, 245, 245, 245);
//   static const Color surface = Color.fromARGB(255, 255, 255, 255);
//   static const Color textPrimary = Color.fromARGB(255, 67, 37, 37);
//   static const Color textSecondary = Color.fromARGB(255, 117, 117, 117);
// }

import 'package:flutter/material.dart';

/// Palette "colorée et dynamique" pour App Gest Lavage.
///
/// Logique :
/// - [primary] -> [secondary] forme le dégradé signature utilisé sur les
///   en-têtes, boutons principaux et badges importants.
/// - [accent] est l'orange utilisé avec parcimonie pour les éléments qui
///   doivent attirer l'œil (CTA secondaires, highlights, stats).
/// - Les couleurs sémantiques (success/warning/error/info) servent aux
///   statuts de réservation et aux retours utilisateur.
class AppColors {
  AppColors._();

  // Dégradé signature
  static const Color primary =
      Color.fromARGB(255, 25, 118, 210); // violet vibrant
  static const Color primaryDark = Color(0xFF4834D4); // violet profond
  static const Color secondary = Color(0xFFFF6B9D); // rose vif
  static const Color accent = Color(0xFFFFA94D); // orange chaleureux

  // Neutres / surfaces
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFF1EEFE); // violet très clair

  // Textes
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF74808C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Statuts
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF54A0FF);

  // Dégradé signature réutilisable partout (app bars, boutons, headers)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Variante plus sobre pour les fonds de carte / chips
  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFEDE9FE), Color(0xFFFCE8F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Couleur associée à un statut de réservation, utilisée partout
  /// pour garder une cohérence visuelle (chips, textes, icônes).
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
      case 'pending':
      case 'en_attente':
        return warning;
      case 'in_progress':
      case 'en_cours':
        return info;
      case 'completed':
      case 'done':
      case 'confirmed':
      case 'terminé':
        return success;
      case 'cancelled':
      case 'annulé':
        return error;
      default:
        return textSecondary;
    }
  }
}
