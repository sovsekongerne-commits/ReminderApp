import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/item_history_repository.dart';
import '../../data/repositories/local_reminder_repository.dart';
import '../../domain/models/reminder.dart';
import '../../domain/reminder_rules.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import 'place_provider.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return LocalReminderRepository();
});

final remindersProvider = NotifierProvider<RemindersNotifier, List<Reminder>>(
  RemindersNotifier.new,
);

class RemindersNotifier extends Notifier<List<Reminder>> {
  late Future<void> _ready;

  @override
  List<Reminder> build() {
    _ready = reload();
    return const [];
  }

  /// Læser sedlerne igen (f.eks. når appen kommer i forgrunden, fordi en
  /// knap på beskeden kan have ændret dem i baggrunden).
  Future<void> reload() async {
    final repo = ref.read(reminderRepositoryProvider);
    state = await repo.getReminders();
    // Overvågning af steder sker i baggrunden – må aldrig blokere listen
    unawaited(_syncGeofences());
  }

  Reminder? byId(String id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> _commit(List<Reminder> next) async {
    state = next;
    await ref.read(reminderRepositoryProvider).saveAll(next);
    unawaited(_syncGeofences());
  }

  Future<void> _syncGeofences() async {
    try {
      final places = ref.read(placesProvider);
      await ref.read(geofenceServiceProvider).sync(places, state);
    } catch (_) {}
  }

  /// Bruges af "Fortryd".
  Future<void> restore(List<Reminder> snapshot) => _commit(snapshot);

  Future<void> addReminder(Reminder reminder) async {
    await _ready;
    await _commit([reminder, ...state]);
    unawaited(() async {
      try {
        await NativeNotificationService().requestPermission();
        await NativeLocationService().requestBackgroundPermission();
      } catch (_) {}
      await _syncGeofences();
    }());
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _ready;
    await _commit([
      for (final r in state)
        if (r.id == reminder.id) reminder else r,
    ]);
  }

  Future<void> deleteReminder(String id) async {
    await _ready;
    await _commit(state.where((r) => r.id != id).toList());
  }

  /// Udført. Faste sedler nulstilles i stedet for at forsvinde.
  Future<void> complete(String id) async {
    await _ready;
    final now = DateTime.now();
    await _commit([
      for (final r in state)
        if (r.id == id) ReminderRules.complete(r, now) else r,
    ]);
  }

  /// Gør en udført seddel aktiv igen ("Brug igen").
  Future<void> reuse(String id) async {
    await _ready;
    await _commit([
      for (final r in state)
        if (r.id == id) r.resetItems().copyWith(clearCompletedAt: true) else r,
    ]);
  }

  /// Krydser et punkt af. Returnerer sand hvis hele listen nu er klaret.
  /// Er [autoComplete] sand, flyttes en engangs-liste til udførte, når
  /// sidste punkt krydses af.
  Future<bool> toggleItem(
    String reminderId,
    String itemId, {
    bool autoComplete = true,
  }) async {
    await _ready;
    var allDone = false;
    final now = DateTime.now();
    final next = [
      for (final r in state)
        if (r.id == reminderId)
          () {
            final toggled = r.copyWith(checklistItems: [
              for (final i in r.checklistItems)
                if (i.id == itemId) i.copyWith(isDone: !i.isDone) else i,
            ]);
            allDone = toggled.allItemsDone;
            if (allDone && autoComplete && !toggled.isRecurring) {
              return toggled.copyWith(completedAt: now);
            }
            return toggled;
          }()
        else
          r,
    ];
    await _commit(next);
    return allDone;
  }

  /// Tilføjer et punkt direkte på en seddel.
  Future<void> addItem(String reminderId, ChecklistItem item) async {
    await _ready;
    await _commit([
      for (final r in state)
        if (r.id == reminderId)
          r.copyWith(checklistItems: [...r.checklistItems, item])
        else
          r,
    ]);
    await ref.read(itemHistoryProvider.notifier).remember(item.text);
  }

  /// Når butikstilstand lukkes: lister hvor alt er krydset af, afsluttes.
  Future<bool> finishAt(String placeId) async {
    await _ready;
    final now = DateTime.now();
    var any = false;
    final next = [
      for (final r in state)
        if (!r.isCompleted && r.isAt(placeId) && r.allItemsDone)
          () {
            any = true;
            return ReminderRules.complete(r, now);
          }()
        else
          r,
    ];
    if (any) await _commit(next);
    return any;
  }

  /// Når et sted slettes: fjern stedet fra sedlerne. Sedler der ikke har
  /// andre steder, slettes også.
  Future<void> removePlace(String placeId) async {
    await _ready;
    await _commit([
      for (final r in state)
        if (!r.isAt(placeId))
          r
        else if (r.placeIds.length > 1)
          r.copyWith(placeIds: r.placeIds.where((p) => p != placeId).toList()),
    ]);
  }
}

/// Ord man har brugt før – til forslag mens man skriver.
final itemHistoryProvider =
    NotifierProvider<ItemHistoryNotifier, List<String>>(ItemHistoryNotifier.new);

class ItemHistoryNotifier extends Notifier<List<String>> {
  final _repo = ItemHistoryRepository();

  @override
  List<String> build() {
    _repo.load().then((v) => state = v);
    return const [];
  }

  Future<void> remember(String word) async {
    state = await _repo.remember(word);
  }

  List<String> suggest(String query, {List<String> exclude = const []}) =>
      ItemHistoryRepository.suggest(state, query, exclude: exclude);
}

/// Valgt sted-filter på forsiden (null = alle).
class PlaceFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? placeId) => state = placeId;
}

final selectedPlaceFilterProvider =
    NotifierProvider<PlaceFilterNotifier, String?>(PlaceFilterNotifier.new);

final activeRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(remindersProvider).where((r) => !r.isCompleted).toList();
});

final completedRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(remindersProvider).where((r) => r.isCompleted).toList();
});
