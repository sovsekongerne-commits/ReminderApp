import 'package:flutter_test/flutter_test.dart';
import 'package:location_reminder/data/repositories/item_history_repository.dart';
import 'package:location_reminder/data/repositories/mock_place_repository.dart';
import 'package:location_reminder/data/repositories/mock_reminder_repository.dart';
import 'package:location_reminder/domain/models/place.dart';
import 'package:location_reminder/domain/models/reminder.dart';
import 'package:location_reminder/domain/reminder_rules.dart';

Reminder _r(
  String id, {
  List<String> places = const ['netto'],
  List<ChecklistItem> items = const [],
  int? after,
  bool recurring = false,
  DateTime? completedAt,
}) =>
    Reminder(
      id: id,
      title: id,
      placeIds: places,
      checklistItems: items,
      afterMinutes: after,
      isRecurring: recurring,
      createdAt: DateTime(2026, 1, 1),
      completedAt: completedAt,
    );

void main() {
  group('MockPlaceRepository', () {
    late MockPlaceRepository placeRepo;
    setUp(() => placeRepo = MockPlaceRepository());

    test('starter med Hjem og Arbejde', () async {
      final places = await placeRepo.getPlaces();
      expect(places.length, 2);
      expect(places.any((p) => p.name == 'Hjem'), true);
      expect(places.any((p) => p.name == 'Arbejde'), true);
    });

    test('savePlace tilføjer et sted', () async {
      await placeRepo.savePlace(Place(
        id: 'test_place',
        name: 'Test',
        latitude: 55.67,
        longitude: 12.56,
        icon: '🏖️',
        createdAt: DateTime.now(),
      ));
      final places = await placeRepo.getPlaces();
      expect(places.any((p) => p.id == 'test_place'), true);
    });
  });

  group('MockReminderRepository', () {
    test('gem og find igen', () async {
      final repo = MockReminderRepository();
      await repo.saveReminder(_r('a'));
      final found = await repo.getReminderById('a');
      expect(found, isNotNull);
      expect(found!.placeIds, ['netto']);
    });
  });

  group('Reminder.fromJson', () {
    test('læser det gamle format (placeId + timeCondition)', () {
      final r = Reminder.fromJson({
        'id': 'old',
        'title': 'Gammel',
        'placeId': 'place_home',
        'triggerType': 'departure',
        'isArrival': false,
        'timeCondition': '2025-10-10T16:30:00.000',
        'createdAt': '2025-10-10T10:00:00.000',
      });
      expect(r.placeIds, ['place_home']);
      expect(r.afterMinutes, 16 * 60 + 30);
      expect(r.afterLabel, '16:30');
      expect(r.isRecurring, false);
    });

    test('nyt format med flere steder', () {
      final r = _r('n', places: ['netto', 'rema'], recurring: true);
      final back = Reminder.fromJson(r.toJson());
      expect(back.placeIds, ['netto', 'rema']);
      expect(back.isRecurring, true);
    });
  });

  group('ReminderRules', () {
    test('dueAt respekterer sted, udført og klokkeslæt', () {
      final all = [
        _r('a'),
        _r('b', places: ['rema']),
        _r('c', after: 16 * 60),
        _r('d', completedAt: DateTime(2026)),
      ];
      final morning = ReminderRules.dueAt(all, 'netto', DateTime(2026, 1, 1, 9));
      expect(morning.map((r) => r.id), ['a']);
      final evening =
          ReminderRules.dueAt(all, 'netto', DateTime(2026, 1, 1, 17));
      expect(evening.map((r) => r.id), ['a', 'c']);
    });

    test('faste lister nulstilles ved ny ankomst', () {
      final all = [
        _r('fast', recurring: true, items: const [
          ChecklistItem(id: '1', text: 'Mælk', isDone: true),
        ]),
      ];
      final reset = ReminderRules.resetRecurringAt(all, 'netto');
      expect(reset.first.checklistItems.first.isDone, false);
    });

    test('udført: fast seddel bliver, engangs-seddel afsluttes', () {
      final now = DateTime(2026);
      expect(ReminderRules.complete(_r('x', recurring: true), now).isCompleted,
          false);
      expect(ReminderRules.complete(_r('y'), now).isCompleted, true);
    });

    test('én samlet tekst til beskeden', () {
      final text = ReminderRules.notificationText([
        _r('Indkøb', items: const [
          ChecklistItem(id: '1', text: 'Mælk'),
          ChecklistItem(id: '2', text: 'Brød', isDone: true),
        ]),
        _r('Pant flasker'),
      ]);
      expect(text.title, '2 ting at huske');
      expect(text.body, '• Indkøb: Mælk\n• Pant flasker');
    });

    test('kun steder med aktive sedler overvåges', () {
      final inUse = ReminderRules.placesInUse([
        _r('a', places: ['netto', 'rema']),
        _r('b', places: ['hjem'], completedAt: DateTime(2026)),
      ]);
      expect(inUse, {'netto', 'rema'});
    });
  });

  group('ItemHistoryRepository.suggest', () {
    test('foreslår ord der starter med det skrevne', () {
      final s = ItemHistoryRepository.suggest(
        ['Mælk', 'Minimælk', 'Mel', 'Kaffe'],
        'm',
        exclude: ['Mel'],
      );
      expect(s, ['Mælk', 'Minimælk']);
    });
  });
}
