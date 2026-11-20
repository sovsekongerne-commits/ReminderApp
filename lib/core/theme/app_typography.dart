import 'package:flutter/material.dart';

/// AppTypography: Let, luftig og tynd typografisk skala med feminin elegance.
class AppTypography {
  AppTypography._();

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400, // Tynd overskrift
    letterSpacing: 0.5,
    height: 1.25,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400, // Tynd
    letterSpacing: 0.4,
    height: 1.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400, // Let og læsevenlig
    letterSpacing: 0.2,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400, // Tynd brødtekst
    letterSpacing: 0.2,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.35,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.9,
    height: 1.2,
  );
}
