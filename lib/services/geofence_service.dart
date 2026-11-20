import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/local_place_repository.dart';
import '../data/repositories/local_reminder_repository.dart';
import '../domain/models/place.dart';
import '../domain/models/reminder.dart';
import '../domain/reminder_rules.dart';
import 'notification_service.dart';

/// Hvor længe der mindst skal gå mellem to beskeder for samme sted.
/// Forhindrer gentagne beskeder, når GPS'en hopper ind og ud ved kanten,
/// eller man går ud og ind af butikken.
const Duration kArrivalCooldown = Duration(minutes: 30);

/// Afvikles af styresystemet i baggrunden, når man ankommer til et sted.
@pragma('vm:entry-point')
Future<void> nativeGeofenceBackgroundCallback(
    GeofenceCallbackParams params) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kun ankomst bruges.
  if (params.event != GeofenceEvent.enter) return;

  final notifications = NativeNotificationService();
  await notifications.initialize();

  final placeRepo = LocalPlaceRepository();
  final reminderRepo = LocalReminderRepository();
  final places = await placeRepo.getPlaces();
  var reminders = await reminderRepo.getReminders();
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();

  for (final geofence in params.geofences) {
    final place = places.where((p) => p.id == geofence.id).firstOrNull;
    if (place == null) continue;

    // Pause mellem beskeder for samme sted
    final key = 'last_arrival_${place.id}';
    final last = prefs.getInt(key);
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            kArrivalCooldown) {
      continue;
    }

    // Faste lister starter forfra ved ny ankomst
    reminders = ReminderRules.resetRecurringAt(reminders, place.id);

    final due = ReminderRules.dueAt(reminders, place.id, now);
    // Intet at huske her → ingen besked (ingen "tjek din huskeseddel"-støj)
    if (due.isEmpty) continue;

    await notifications.showArrival(place: place, due: due);
    await prefs.setInt(key, now.millisecondsSinceEpoch);
  }

  await reminderRepo.saveAll(reminders);
}

/// Styrer hvilke steder telefonen holder øje med.
abstract class GeofenceService {
  Future<void> initialize();
  Future<void> sync(List<Place> places, List<Reminder> reminders);
  Future<void> unregisterGeofence(String id);
}

class NativeGeofenceService implements GeofenceService {
  static final NativeGeofenceService _instance =
      NativeGeofenceService._internal();
  factory NativeGeofenceService() => _instance;
  NativeGeofenceService._internal();

  bool _isInitialized = false;

  /// Hvad der sidst blev registreret: id → "lat,lng,radius".
  /// Så vi kun kalder styresystemet, når noget faktisk har ændret sig.
  final Map<String, String> _registered = {};

  @override
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;
    try {
      await NativeGeofenceManager.instance.initialize();
      _isInitialized = true;
      final ids = await NativeGeofenceManager.instance
          .getRegisteredGeofenceIds();
      for (final id in ids) {
        _registered[id] = '';
      }
    } catch (e) {
      debugPrint('Fejl ved initialisering af NativeGeofenceManager: $e');
    }
  }

  /// Registrerer ankomst-overvågning for alle steder med aktive sedler,
  /// og fjerner den for steder uden noget at huske.
  @override
  Future<void> sync(List<Place> places, List<Reminder> reminders) async {
    if (kIsWeb) return;
    await initialize();
    if (!_isInitialized) return;

    final inUse = ReminderRules.placesInUse(reminders);

    for (final place in places) {
      final signature =
          '${place.latitude},${place.longitude},${place.radiusMeters}';
      if (inUse.contains(place.id)) {
        if (_registered[place.id] == signature) continue;
        try {
          await NativeGeofenceManager.instance.createGeofence(
            Geofence(
              id: place.id,
              location: Location(
                latitude: place.latitude,
                longitude: place.longitude,
              ),
              radiusMeters: place.radiusMeters,
              triggers: const {GeofenceEvent.enter},
              iosSettings: const IosGeofenceSettings(initialTrigger: false),
              androidSettings:
                  const AndroidGeofenceSettings(initialTriggers: {}),
            ),
            nativeGeofenceBackgroundCallback,
          );
          _registered[place.id] = signature;
        } catch (e) {
          debugPrint('Fejl ved registrering af geofence ${place.id}: $e');
        }
      } else if (_registered.containsKey(place.id)) {
        await unregisterGeofence(place.id);
      }
    }

    // Steder der er slettet
    final known = places.map((p) => p.id).toSet();
    for (final id in _registered.keys.toList()) {
      if (!known.contains(id)) await unregisterGeofence(id);
    }
  }

  @override
  Future<void> unregisterGeofence(String id) async {
    if (kIsWeb) return;
    await initialize();
    try {
      await NativeGeofenceManager.instance.removeGeofenceById(id);
    } catch (e) {
      debugPrint('Fejl ved fjernelse af geofence $id: $e');
    }
    _registered.remove(id);
  }
}
