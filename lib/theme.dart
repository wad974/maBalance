import 'package:flutter/material.dart';

/// Palette douce et moderne de l'application.
class AppCouleurs {
  static const menthe = Color(0xFF2EC4A6);
  static const mentheFonce = Color(0xFF169C83);
  static const lavande = Color(0xFF8B7CF6);
  static const peche = Color(0xFFFF9F7A);
  static const corail = Color(0xFFFF6B6B);
  static const soleil = Color(0xFFFFC857);
  static const encre = Color(0xFF1F2A44);
  static const gris = Color(0xFF7A8499);
  static const fond = Color(0xFFF4F7FB);

  static const degradeFond = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6FBF5), Color(0xFFF1EEFF), Color(0xFFFFF1EA)],
  );

  static const degradePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [menthe, lavande],
  );
}

ThemeData construireTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppCouleurs.menthe,
      primary: AppCouleurs.mentheFonce,
      secondary: AppCouleurs.lavande,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppCouleurs.fond,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppCouleurs.encre,
      displayColor: AppCouleurs.encre,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6EAF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppCouleurs.menthe, width: 2),
      ),
      labelStyle: const TextStyle(color: AppCouleurs.gris),
    ),
  );
}

/// Couleurs des graphiques (vérifiées pour le daltonisme).
class CouleursGraph {
  static const perte = Color(0xFF1E88A8);
  static const prise = Color(0xFFE07A45);
  static const stable = Color(0xFFB8BFCC);
  static const ligne = Color(0xFF1E88A8);
  static const piste = Color(0xFFE3E7EF);
  static const grille = Color(0xFFEDF0F5);
}
