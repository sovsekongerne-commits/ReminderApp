import 'models/reminder.dart';

/// Rene regler for huskesedler. Bruges både af appen og af
/// baggrunds-koden, der kører når telefonen opdager en ankomst.
class ReminderRules {
  ReminderRules._();

  /// Sedler der skal vises, når man ankommer til [placeId] på tidspunktet [now].
  static List<Reminder> dueAt(
    List<Reminder> all,
    String placeId,
    DateTime now,
  ) {
    return all
        .where((r) =>
            r.enabled && !r.isCompleted && r.isAt(placeId) && r.timeAllows(now))
        .toList();
  }

  /// Aktive sedler (ikke udført) for et sted – uanset klokkeslæt.
  static List<Reminder> activeAt(List<Reminder> all, String placeId) {
    return all.where((r) => !r.isCompleted && r.isAt(placeId)).toList();
  }

  /// "Mind mig hver gang": lister hvor alt var krydset af, starter forfra
  /// ved en ny ankomst.
  static List<Reminder> resetRecurringAt(List<Reminder> all, String placeId) {
    return [
      for (final r in all)
        if (r.isRecurring && r.isAt(placeId) && r.allItemsDone)
          r.resetItems()
        else
          r,
    ];
  }

  /// Markér som udført. Faste sedler nulstilles i stedet for at forsvinde.
  static Reminder complete(Reminder r, DateTime now) {
    return r.isRecurring ? r.resetItems() : r.copyWith(completedAt: now);
  }

  /// Steder der har mindst én aktiv seddel (og derfor skal overvåges).
  static Set<String> placesInUse(List<Reminder> all) {
    return {
      for (final r in all)
        if (!r.isCompleted && r.enabled) ...r.placeIds,
    };
  }

  /// Tekst til notifikationen.
  /// Én seddel: punkterne der mangler. Flere: én linje pr. seddel.
  static ({String title, String body}) notificationText(
    List<Reminder> due,
  ) {
    String openItems(Reminder r) => r.checklistItems
        .where((i) => !i.isDone)
        .map((i) => i.text)
        .join(', ');

    if (due.length == 1) {
      final r = due.first;
      final items = openItems(r);
      return (title: r.title, body: items);
    }
    final lines = due.map((r) {
      final items = openItems(r);
      return items.isEmpty ? '• ${r.title}' : '• ${r.title}: $items';
    }).join('\n');
    return (title: '${due.length} ting at huske', body: lines);
  }
}
