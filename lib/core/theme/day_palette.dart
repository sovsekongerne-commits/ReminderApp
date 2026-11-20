import 'package:flutter/material.dart';

/// Tidspunkt på dagen. Bruges til hilsen, emoji og appens farver.
enum DayPhase { morning, day, evening, night }

DayPhase dayPhaseFor(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 10) return DayPhase.morning;
  if (h >= 10 && h < 17) return DayPhase.day;
  if (h >= 17 && h < 23) return DayPhase.evening;
  return DayPhase.night;
}

/// Farver der følger tidspunktet på dagen.
/// Alle accentfarver har mindst 4.5:1 kontrast mod hvid tekst (lyst tema)
/// eller mod sort tekst (mørkt tema).
class DayPalette {
  final DayPhase phase;
  final String greeting;
  final String emoji;
  final Color background;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color soft;
  final Color softInk;
  final Color ink;

  const DayPalette({
    required this.phase,
    required this.greeting,
    required this.emoji,
    required this.background,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.soft,
    required this.softInk,
    required this.ink,
  });

  static DayPalette of(DayPhase phase, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (phase) {
      case DayPhase.morning:
        return dark
            ? const DayPalette(
                phase: DayPhase.morning, greeting: 'Godmorgen', emoji: '☕',
                background: Color(0xFF221D16), line: Color(0xFF3D3324),
                accent: Color(0xFFE2B56B), onAccent: Colors.black,
                soft: Color(0xFF3A2F1E), softInk: Color(0xFFF0CF96), ink: Color(0xFFE2B56B))
            : const DayPalette(
                phase: DayPhase.morning, greeting: 'Godmorgen', emoji: '☕',
                background: Color(0xFFFDF5E6), line: Color(0xFFEEDFC2),
                accent: Color(0xFF946519), onAccent: Colors.white,
                soft: Color(0xFFF8E6C4), softInk: Color(0xFF6E4A10), ink: Color(0xFF7A5418));
      case DayPhase.day:
        return dark
            ? const DayPalette(
                phase: DayPhase.day, greeting: 'Goddag', emoji: '☀️',
                background: Color(0xFF161D20), line: Color(0xFF26343A),
                accent: Color(0xFF7FC0D3), onAccent: Colors.black,
                soft: Color(0xFF1F3038), softInk: Color(0xFFA9D7E4), ink: Color(0xFF7FC0D3))
            : const DayPalette(
                phase: DayPhase.day, greeting: 'Goddag', emoji: '☀️',
                background: Color(0xFFF0F6F8), line: Color(0xFFD7E5EA),
                accent: Color(0xFF2F6B7E), onAccent: Colors.white,
                soft: Color(0xFFD9EAF0), softInk: Color(0xFF24566A), ink: Color(0xFF2F5E6E));
      case DayPhase.evening:
        return dark
            ? const DayPalette(
                phase: DayPhase.evening, greeting: 'Godaften', emoji: '🌅',
                background: Color(0xFF1E1A19), line: Color(0xFF4A423E),
                accent: Color(0xFFDE9E9E), onAccent: Colors.black,
                soft: Color(0xFF3B2E2E), softInk: Color(0xFFF2C3C3), ink: Color(0xFFE8A88E))
            : const DayPalette(
                phase: DayPhase.evening, greeting: 'Godaften', emoji: '🌅',
                background: Color(0xFFFBF2EC), line: Color(0xFFEFDDD2),
                accent: Color(0xFFA65E5E), onAccent: Colors.white,
                soft: Color(0xFFF6E4E4), softInk: Color(0xFF8A4A4A), ink: Color(0xFF8A4A35));
      case DayPhase.night:
        return dark
            ? const DayPalette(
                phase: DayPhase.night, greeting: 'Godnat', emoji: '🌙',
                background: Color(0xFF1A1820), line: Color(0xFF332F3E),
                accent: Color(0xFFB7A6DB), onAccent: Colors.black,
                soft: Color(0xFF2C2638), softInk: Color(0xFFD2C6EC), ink: Color(0xFFB7A6DB))
            : const DayPalette(
                phase: DayPhase.night, greeting: 'Godnat', emoji: '🌙',
                background: Color(0xFFF3F0F8), line: Color(0xFFE0D9EC),
                accent: Color(0xFF6B5690), onAccent: Colors.white,
                soft: Color(0xFFE6DFF1), softInk: Color(0xFF54437A), ink: Color(0xFF5B4878));
    }
  }

  /// Nem adgang fra widgets: følger det aktuelle tema og klokken.
  static DayPalette current(BuildContext context) {
    return DayPalette.of(
      dayPhaseFor(DateTime.now()),
      Theme.of(context).brightness,
    );
  }
}
