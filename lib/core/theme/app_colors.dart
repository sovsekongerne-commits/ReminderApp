import 'package:flutter/material.dart';

/// AppColors: Feminin, rolig og varm palette i beige, grå og bløde pasteller.
class AppColors {
  AppColors._();

  // --- Lyst tema: Varm havre/hør, bløde sandtoner og puddergrå ---
  static const Color lightBackground = Color(
    0xFFFAF7F2,
  ); // Varm havregryn / lin
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(
    0xFFF3ECE4,
  ); // Blød varm sand/grå
  static const Color lightBorder = Color(0xFFEBE3D8); // Diskret varm kant
  static const Color lightBorderStrong = Color(0xFFDED4C7);

  static const Color lightTextPrimary = Color(
    0xFF332D2B,
  ); // Dyb varm espresso-grå
  static const Color lightTextSecondary = Color(
    0xFF7D756F,
  ); // Varm dæmpet taupe-grå
  static const Color lightTextMuted = Color(0xFFAAA199); // Lys pudret grå

  // --- Mørkt tema: Varm espresso, blød mocca og dæmpet rosé ---
  static const Color darkBackground = Color(0xFF1E1A19); // Dyb varm espresso
  static const Color darkSurface = Color(0xFF292422); // Varm mocca
  static const Color darkSurfaceElevated = Color(0xFF342E2C);
  static const Color darkSurfaceSubtle = Color(0xFF3F3734);
  static const Color darkBorder = Color(0xFF4A423E);
  static const Color darkBorderStrong = Color(0xFF5E544F);

  static const Color darkTextPrimary = Color(0xFFF8F4F0);
  static const Color darkTextSecondary = Color(0xFFB8ADA4);
  static const Color darkTextMuted = Color(0xFF857B74);

  // --- Feminin Signatur Accent: Støvet Rose / Blush ---
  static const Color accent = Color(0xFFC07E7E); // Støvet blush rosé
  static const Color accentLight = Color(0xFFDE9E9E); // Lys pastel rosé
  static const Color accentSubtleLight = Color(0xFFFAF0F0); // Ultrablød pudder
  static const Color accentSubtleDark = Color(0xFF3B2E2E);

  // --- Bløde Pasteller ---
  static const Color pastelSage = Color(0xFFD6E3D4); // Salviegrøn
  static const Color pastelSageText = Color(0xFF577455);

  static const Color pastelPeach = Color(0xFFFCE6DB); // Fersken/nude
  static const Color pastelPeachText = Color(0xFFA56644);

  static const Color pastelLavender = Color(0xFFEAE2F2); // Blid lavendel
  static const Color pastelLavenderText = Color(0xFF755E8D);

  static const Color pastelSand = Color(0xFFF5EFE6); // Sand
  static const Color pastelSandText = Color(0xFF806E58);

  // Semantiske toner
  static const Color success = Color(0xFF7DA77D); // Dæmpet salviegrøn succes
  static const Color successSubtle = Color(0xFFF1F7F1);
  static const Color destructive = Color(0xFFCE6767); // Blød hindbærrød
  static const Color destructiveSubtle = Color(0xFFFDF0F0);
  static const Color timeAccent = Color(0xFFC68A57); // Varm rav/karamel
  static const Color timeAccentSubtle = Color(0xFFFCF5EE);
}
