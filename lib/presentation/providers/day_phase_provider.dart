import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/day_palette.dart';

/// Tidspunkt på dagen. Tjekkes hvert minut, så farver og hilsen skifter
/// af sig selv, mens appen er åben.
final dayPhaseProvider = NotifierProvider<DayPhaseNotifier, DayPhase>(
  DayPhaseNotifier.new,
);

class DayPhaseNotifier extends Notifier<DayPhase> {
  @override
  DayPhase build() {
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    ref.onDispose(timer.cancel);
    return dayPhaseFor(DateTime.now());
  }

  void refresh() {
    final now = dayPhaseFor(DateTime.now());
    if (now != state) state = now;
  }
}
