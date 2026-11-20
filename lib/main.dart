import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/day_palette.dart';
import 'presentation/providers/day_phase_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'services/geofence_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Notifikationer (med knapperne Udført / Næste gang) og geofence-motor
  await NativeNotificationService().initialize();
  await NativeGeofenceService().initialize();

  runApp(const ProviderScope(child: LocationReminderApp()));

  // Blev appen åbnet ved et tryk på en besked? → åbn butikstilstand
  await NativeNotificationService().handleLaunch();
}

class LocationReminderApp extends ConsumerWidget {
  const LocationReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final phase = ref.watch(dayPhaseProvider);

    return MaterialApp(
      title: 'Sted & Påmindelse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(DayPalette.of(phase, Brightness.light)),
      darkTheme: AppTheme.dark(DayPalette.of(phase, Brightness.dark)),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
