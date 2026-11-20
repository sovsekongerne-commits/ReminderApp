import 'package:flutter/services.dart';

/// AppHaptics wraps subtle, tactile vibrations for key micro-interactions.
class AppHaptics {
  AppHaptics._();

  /// Light tick on toggling checkboxes or selecting options
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium tap on primary saves or deletions
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Subtle click on selecting a place chip
  static void selection() {
    HapticFeedback.selectionClick();
  }
}
