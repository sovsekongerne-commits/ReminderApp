import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/repositories/local_reminder_repository.dart';
import '../domain/models/place.dart';
import '../domain/models/reminder.dart';
import '../domain/reminder_rules.dart';

const String kChannelId = 'location_reminders_channel';
const String kChannelName = 'Sted-påmindelser';
const String kChannelDescription =
    'Giver dig besked, når du ankommer til dine gemte steder';
const String kCategoryArrival = 'place_arrival';
const String kActionDone = 'done';
const String kActionLater = 'later';
const String kPayloadTest = 'test';

/// Kører i en baggrunds-isolate, når man trykker "Udført" eller
/// "Næste gang" på beskeden uden at åbne appen.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await handleNotificationAction(response);
}

/// "Udført" markerer alle sedler, der stod i beskeden, som klaret.
/// Faste sedler ("Mind mig hver gang") nulstilles i stedet.
/// "Næste gang" gør ingenting – beskeden lukkes bare.
Future<void> handleNotificationAction(NotificationResponse response) async {
  if (response.actionId != kActionDone) return;
  final placeId = response.payload;
  if (placeId == null || placeId.isEmpty || placeId == kPayloadTest) return;

  final repo = LocalReminderRepository();
  final all = await repo.getReminders();
  final now = DateTime.now();
  final updated = [
    for (final r in all)
      if (r.enabled && !r.isCompleted && r.isAt(placeId) && r.timeAllows(now))
        ReminderRules.complete(r, now)
      else
        r,
  ];
  await repo.saveAll(updated);
}

/// Lokale notifikationer.
class NativeNotificationService {
  static final NativeNotificationService _instance =
      NativeNotificationService._internal();
  factory NativeNotificationService() => _instance;
  NativeNotificationService._internal();

  /// Sættes til et steds id, når man trykker på en besked. Forsiden lytter
  /// og åbner butikstilstand for stedet.
  static final ValueNotifier<String?> openPlaceRequest =
      ValueNotifier<String?>(null);

  /// Tælles op, når en knap på beskeden har ændret data mens appen kører.
  static final ValueNotifier<int> dataChanged = ValueNotifier<int>(0);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static void _onResponse(NotificationResponse response) async {
    if (response.actionId == kActionDone) {
      await handleNotificationAction(response);
      dataChanged.value++;
      return;
    }
    if (response.actionId == kActionLater) return;
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty && payload != kPayloadTest) {
      openPlaceRequest.value = payload;
    }
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (kIsWeb) return false;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            kCategoryArrival,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(kActionDone, 'Udført'),
              DarwinNotificationAction.plain(kActionLater, 'Næste gang'),
            ],
          ),
        ],
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onResponse,
        onDidReceiveBackgroundNotificationResponse:
            notificationBackgroundHandler,
      );
      _isInitialized = result ?? true;

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
          await androidPlugin?.createNotificationChannel(
            const AndroidNotificationChannel(
              kChannelId,
              kChannelName,
              description: kChannelDescription,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
        } catch (_) {}
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('Kunne ikke initialisere notifikationer: $e');
      return false;
    }
  }

  /// Hvis appen blev startet ved et tryk på en besked.
  Future<void> handleLaunch() async {
    if (kIsWeb) return;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if ((details?.didNotificationLaunchApp ?? false) && response != null) {
        _onResponse(response);
      }
    } catch (_) {}
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.requestNotificationsPermission() ?? true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            true;
      }
    } catch (e) {
      debugPrint('Fejl ved forespørgsel om notifikationstilladelse: $e');
    }
    return true;
  }

  /// Er notifikationer slået til? (null = ukendt)
  Future<bool?> areEnabled() async {
    if (kIsWeb) return null;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled();
      }
    } catch (_) {}
    return null;
  }

  static int idForPlace(String placeId) => placeId.hashCode & 0x7fffffff;

  NotificationDetails _details({String? bigText}) {
    final android = AndroidNotificationDetails(
      kChannelId,
      kChannelName,
      channelDescription: kChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation:
          bigText == null ? null : BigTextStyleInformation(bigText),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(kActionDone, 'Udført'),
        AndroidNotificationAction(kActionLater, 'Næste gang'),
      ],
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      categoryIdentifier: kCategoryArrival,
      threadIdentifier: 'arrivals',
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  /// Én samlet besked pr. sted, med de punkter der mangler.
  Future<void> showArrival({
    required Place place,
    required List<Reminder> due,
  }) async {
    if (due.isEmpty) return;
    await initialize();
    final text = ReminderRules.notificationText(due);
    final body = due.length == 1
        ? (text.body.isEmpty ? text.title : '${text.title}: ${text.body}')
        : '${text.title}\n${text.body}';
    try {
      await _plugin.show(
        id: idForPlace(place.id),
        title: '${place.icon} Du er ved ${place.name}',
        body: body,
        notificationDetails: _details(bigText: body),
        payload: place.id,
      );
    } catch (e) {
      debugPrint('Fejl ved visning af notifikation: $e');
    }
  }

  Future<void> showTest() async {
    await initialize();
    const android = AndroidNotificationDetails(
      kChannelId,
      kChannelName,
      channelDescription: kChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
    );
    try {
      await _plugin.show(
        id: 7777,
        title: 'Sted & Påmindelse 🌸',
        body: 'Dine beskeder virker! Du får besked, når du ankommer til dine steder.',
        notificationDetails:
            const NotificationDetails(android: android, iOS: ios),
        payload: kPayloadTest,
      );
    } catch (e) {
      debugPrint('Fejl ved visning af notifikation: $e');
    }
  }

  Future<void> cancelForPlace(String placeId) async {
    try {
      await _plugin.cancel(id: idForPlace(placeId));
    } catch (_) {}
  }
}
