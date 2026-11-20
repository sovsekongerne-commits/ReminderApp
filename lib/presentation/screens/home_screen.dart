import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/day_palette.dart';
import '../../core/utils/haptics.dart';
import '../../domain/models/place.dart';
import '../../domain/models/reminder.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../providers/day_phase_provider.dart';
import '../providers/place_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/create_place_sheet.dart';
import '../widgets/create_reminder_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/grandma_tutorial_sheet.dart';
import '../widgets/places_bar.dart';
import '../widgets/reminder_card.dart';
import 'store_mode_screen.dart';

enum _PermissionProblem { none, location, notifications }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _showCompleted = false;
  _PermissionProblem _problem = _PermissionProblem.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeNotificationService.openPlaceRequest.addListener(_onOpenRequest);
    NativeNotificationService.dataChanged.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsOnStart();
      _onOpenRequest();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NativeNotificationService.openPlaceRequest.removeListener(_onOpenRequest);
    NativeNotificationService.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Knapper på beskeden kan have ændret sedlerne i baggrunden
      ref.read(remindersProvider.notifier).reload();
      ref.read(dayPhaseProvider.notifier).refresh();
      _checkPermissions();
    }
  }

  void _onDataChanged() => ref.read(remindersProvider.notifier).reload();

  void _onOpenRequest() {
    final placeId = NativeNotificationService.openPlaceRequest.value;
    if (placeId == null || !mounted) return;
    NativeNotificationService.openPlaceRequest.value = null;
    _openStore(placeId);
  }

  // ---------------------------------------------------------------------------
  // Tilladelser
  // ---------------------------------------------------------------------------

  Future<void> _requestPermissionsOnStart() async {
    try {
      await NativeNotificationService().requestPermission();
      await NativeLocationService().requestForegroundPermission();
    } catch (_) {}
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) return;
    var problem = _PermissionProblem.none;
    try {
      final hasPlaceNotes =
          ref.read(activeRemindersProvider).any((r) => r.placeIds.isNotEmpty);
      if (hasPlaceNotes) {
        final always = await Permission.locationAlways.status;
        final notif = await Permission.notification.status;
        if (!always.isGranted) {
          problem = _PermissionProblem.location;
        } else if (!notif.isGranted) {
          problem = _PermissionProblem.notifications;
        }
      }
    } catch (_) {}
    if (mounted && problem != _problem) setState(() => _problem = problem);
  }

  Future<void> _fixPermissions() async {
    AppHaptics.medium();
    try {
      if (_problem == _PermissionProblem.location) {
        final ok = await NativeLocationService().requestBackgroundPermission();
        if (!ok) await openAppSettings();
      } else if (_problem == _PermissionProblem.notifications) {
        final ok = await NativeNotificationService().requestPermission();
        if (!ok) await openAppSettings();
      }
    } catch (_) {}
    await _checkPermissions();
  }

  // ---------------------------------------------------------------------------
  // Beskeder nederst (med Fortryd)
  // ---------------------------------------------------------------------------

  void _toast(String text, {List<Reminder>? undoSnapshot}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        content: Text(text),
        action: undoSnapshot == null
            ? null
            : SnackBarAction(
                label: AppStrings.undo,
                onPressed: () =>
                    ref.read(remindersProvider.notifier).restore(undoSnapshot),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Handlinger
  // ---------------------------------------------------------------------------

  Future<void> _complete(Reminder r) async {
    final snap = ref.read(remindersProvider);
    await ref.read(remindersProvider.notifier).complete(r.id);
    _toast(
      r.isRecurring ? 'Klaret – den kommer igen næste gang' : 'Udført',
      undoSnapshot: snap,
    );
  }

  Future<void> _delete(Reminder r) async {
    final snap = ref.read(remindersProvider);
    await ref.read(remindersProvider.notifier).deleteReminder(r.id);
    _toast('Sedlen er slettet', undoSnapshot: snap);
  }

  Future<void> _toggleItem(Reminder r, String itemId) async {
    final snap = ref.read(remindersProvider);
    final allDone =
        await ref.read(remindersProvider.notifier).toggleItem(r.id, itemId);
    if (allDone) {
      AppHaptics.medium();
      _toast(
        r.isRecurring
            ? 'Alt er klaret – listen er klar til næste gang'
            : 'Alt er klaret – sedlen er flyttet til udførte',
        undoSnapshot: snap,
      );
    }
  }

  void _addItem(Reminder r, String text) {
    ref.read(remindersProvider.notifier).addItem(
          r.id,
          ChecklistItem(id: const Uuid().v4(), text: text),
        );
  }

  Future<void> _openStore(String placeId) async {
    final place = ref.read(placesProvider.notifier).getPlaceById(placeId);
    if (place == null) return;
    final msg = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => StoreModeScreen(placeId: placeId)),
    );
    if (msg != null) _toast(msg);
  }

  Future<Place?> _createPlaceHere() async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePlaceSheet(startWithCurrentLocation: true),
    );
    if (place != null) {
      await ref.read(placesProvider.notifier).savePlace(place);
    }
    return place;
  }

  void _openSheet({
    Reminder? existing,
    String? placeId,
    List<String> presetItems = const [],
  }) {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      backgroundColor: Colors.transparent,
      builder: (_) => CreateReminderSheet(
        places: ref.read(placesProvider),
        existingReminder: existing,
        preselectedPlaceId: placeId ?? ref.read(selectedPlaceFilterProvider),
        presetItems: presetItems,
        onCreatePlaceHere: _createPlaceHere,
        onDelete: existing == null ? null : () => _delete(existing),
        onReminderSaved: (reminder) {
          if (existing != null) {
            ref.read(remindersProvider.notifier).updateReminder(reminder);
            _toast('Ændringer gemt');
          } else {
            ref
                .read(remindersProvider.notifier)
                .addReminder(reminder)
                .then((_) => _checkPermissions());
            final names = reminder.placeIds
                .map((id) =>
                    ref.read(placesProvider.notifier).getPlaceById(id)?.name)
                .whereType<String>()
                .join(' og ');
            _toast('Gemt – du får besked ved $names 🌸');
          }
        },
      ),
    );
  }

  void _openPlaceSheet({Place? existing}) {
    AppHaptics.light();
    showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePlaceSheet(
        existingPlace: existing,
        onDelete: existing == null ? null : () => _confirmDeletePlace(existing),
      ),
    ).then((place) {
      if (place != null) {
        ref.read(placesProvider.notifier).savePlace(place);
        if (existing == null) {
          ref.read(selectedPlaceFilterProvider.notifier).setFilter(place.id);
          _toast('${place.name} er gemt');
        } else {
          _toast('Stedet er opdateret');
        }
      }
    });
  }

  void _confirmDeletePlace(Place place) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
        title: Text('Slet "${place.name}"?'),
        content: const Text(
          'Sedler der kun hører til dette sted, slettes også. '
          'Sedler med andre steder bliver bevaret.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            onPressed: () {
              Navigator.of(ctx).pop();
              AppHaptics.medium();
              if (ref.read(selectedPlaceFilterProvider) == place.id) {
                ref.read(selectedPlaceFilterProvider.notifier).setFilter(null);
              }
              ref.read(placesProvider.notifier).deletePlace(place.id);
              _toast('${place.name} er slettet');
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _openTutorial() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      backgroundColor: Colors.transparent,
      builder: (_) => GrandmaTutorialSheet(
        onSampleReminderRequested: () {
          final places = ref.read(placesProvider);
          final sample = Reminder(
            id: const Uuid().v4(),
            title: 'Tag posten ind 📬',
            placeIds: places.isNotEmpty ? [places.first.id] : const [],
            createdAt: DateTime.now(),
          );
          ref.read(remindersProvider.notifier).addReminder(sample);
          _toast('Prøve-seddel oprettet! 🌸');
        },
      ),
    );
  }

  Future<void> _testNotification() async {
    AppHaptics.medium();
    final granted = await NativeNotificationService().requestPermission();
    await NativeNotificationService().showTest();
    _toast(granted
        ? 'Prøvebesked sendt – kig øverst på skærmen 🔔'
        : 'Giv tilladelse til beskeder under Indstillinger');
  }

  // ---------------------------------------------------------------------------
  // Tekster
  // ---------------------------------------------------------------------------

  static const _days = [
    'mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag',
  ];
  static const _months = [
    'januar', 'februar', 'marts', 'april', 'maj', 'juni', 'juli', 'august',
    'september', 'oktober', 'november', 'december',
  ];

  String _dateText() {
    final now = DateTime.now();
    return '${_days[now.weekday - 1]} ${now.day}. ${_months[now.month - 1]}'
        .toUpperCase();
  }

  String _subline(List<Reminder> active, List<Place> places) {
    if (active.isEmpty) return 'Du har intet at huske lige nu';
    final names = [
      for (final p in places)
        if (active.any((r) => r.isAt(p.id))) p.name,
    ];
    final where = names.length > 2
        ? '${names.take(2).join(', ')} m.fl.'
        : names.join(' og ');
    final count = active.length == 1 ? '1 ting' : '${active.length} ting';
    return where.isEmpty ? '$count at huske' : '$count at huske ved $where';
  }

  // ---------------------------------------------------------------------------
  // Byg
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(dayPhaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pal = DayPalette.current(context);
    final places = ref.watch(placesProvider);
    final active = ref.watch(activeRemindersProvider);
    final completed = ref.watch(completedRemindersProvider);
    final filter = ref.watch(selectedPlaceFilterProvider);
    final filterPlace =
        filter == null ? null : places.where((p) => p.id == filter).firstOrNull;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final counts = <String, int>{
      for (final p in places) p.id: active.where((r) => r.isAt(p.id)).length,
    };

    // Grupper: ét afsnit pr. sted. En seddel med flere steder står under hvert.
    final shownPlaces = filterPlace == null ? places : [filterPlace];
    final groups = [
      for (final p in shownPlaces)
        (place: p, notes: active.where((r) => r.isAt(p.id)).toList()),
    ].where((g) => g.notes.isNotEmpty || filterPlace != null).toList();
    final knownIds = places.map((p) => p.id).toSet();
    final orphans = filterPlace != null
        ? <Reminder>[]
        : active.where((r) => !r.placeIds.any(knownIds.contains)).toList();

    List<String> otherNames(Reminder r, String? exceptId) => [
          for (final id in r.placeIds)
            if (id != exceptId)
              ...places.where((p) => p.id == id).map((p) => p.name),
        ];

    Widget card(Reminder r, String? groupId) => ReminderCard(
          key: ValueKey('card_${r.id}_$groupId'),
          reminder: r,
          groupPlaceId: groupId,
          otherPlaceNames: otherNames(r, groupId),
          onComplete: () => _complete(r),
          onDelete: () => _delete(r),
          onEdit: () => _openSheet(existing: r),
          onToggleItem: (itemId) => _toggleItem(r, itemId),
          onAddItem: (text) => _addItem(r, text),
        );

    Widget groupHeader(String icon, String title, {VoidCallback? onOpen}) =>
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 6),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.micro.copyWith(color: textSecondary),
                ),
              ),
              if (onOpen != null)
                TextButton.icon(
                  onPressed: onOpen,
                  icon: Icon(Icons.open_in_full_rounded,
                      size: 14, color: pal.accent),
                  label: Text('Åbn',
                      style: AppTypography.label.copyWith(
                          color: pal.accent, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: pal.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HILSEN
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding, AppSpacing.lg, 8, AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateText(),
                                style: AppTypography.micro.copyWith(
                                    color: pal.ink, letterSpacing: 0.6),
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: pal.greeting),
                                  TextSpan(
                                    text: '  ${pal.emoji}',
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ]),
                                style: AppTypography.display.copyWith(
                                    color: textPrimary, fontSize: 30),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _subline(active, places),
                                style: AppTypography.body
                                    .copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Menu',
                          icon: Icon(Icons.more_horiz_rounded,
                              color: textSecondary),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedLg),
                          onSelected: (v) {
                            switch (v) {
                              case 'guide':
                                _openTutorial();
                              case 'test':
                                _testNotification();
                              case 'theme':
                                ref
                                    .read(themeModeProvider.notifier)
                                    .toggleTheme();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'guide', child: Text('Nem vejledning')),
                            PopupMenuItem(
                                value: 'test',
                                child: Text('Send en prøvebesked')),
                            PopupMenuItem(
                                value: 'theme',
                                child: Text('Skift lyst / mørkt tema')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ADVARSEL OM TILLADELSER
                if (_problem != _PermissionProblem.none)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding, 10, AppSpacing.screenPadding, 0),
                      child: _PermissionBanner(
                        title: _problem == _PermissionProblem.location
                            ? 'Appen kan ikke se, når du ankommer'
                            : 'Beskeder er slået fra',
                        message: _problem == _PermissionProblem.location
                            ? 'Vælg "Tillad altid" ved placering.'
                            : 'Slå beskeder til, ellers får du ingen påmindelser.',
                        onFix: _fixPermissions,
                      ),
                    ),
                  ),

                // SEDLER PR. STED
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (active.isEmpty && filterPlace == null)
                        EmptyRemindersView(
                          isFiltered: false,
                          onAddTap: () => _openSheet(),
                          onTutorialTap: _openTutorial,
                          onTestNotification: _testNotification,
                        ),
                      for (final g in groups) ...[
                        groupHeader(
                          g.place.icon,
                          'NÅR DU KOMMER TIL ${g.place.name.toUpperCase()}',
                          onOpen: g.notes.isEmpty
                              ? null
                              : () => _openStore(g.place.id),
                        ),
                        for (final r in g.notes) card(r, g.place.id),
                        if (g.notes.isEmpty)
                          EmptyRemindersView(
                            isFiltered: true,
                            onAddTap: () => _openSheet(placeId: g.place.id),
                          ),
                      ],
                      if (orphans.isNotEmpty) ...[
                        groupHeader('📍', 'MANGLER ET STED – TRYK FOR AT VÆLGE'),
                        for (final r in orphans) card(r, null),
                      ],

                      // UDFØRTE
                      if (completed.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        InkWell(
                          borderRadius: AppRadius.roundedSm,
                          onTap: () =>
                              setState(() => _showCompleted = !_showCompleted),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Text('Udførte (${completed.length})',
                                    style: AppTypography.label
                                        .copyWith(color: textSecondary)),
                                Icon(
                                  _showCompleted
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showCompleted)
                          for (final r in completed)
                            _CompletedRow(
                              reminder: r,
                              icon: places
                                      .where((p) => r.isAt(p.id))
                                      .map((p) => p.icon)
                                      .firstOrNull ??
                                  '📍',
                              onReuse: () {
                                ref.read(remindersProvider.notifier).reuse(r.id);
                                _toast('Sedlen er aktiv igen');
                              },
                              onDelete: () => _delete(r),
                            ),
                      ],
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // BUND: STEDER + NY SEDDEL (tommelfinger-zonen)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: pal.background,
          border: Border(top: BorderSide(color: pal.line)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlacesBar(
                      places: places,
                      selectedPlaceId: filter,
                      counts: counts,
                      onPlaceSelected: (id) => ref
                          .read(selectedPlaceFilterProvider.notifier)
                          .setFilter(id),
                      onPlaceLongPress: (p) => _openPlaceSheet(existing: p),
                      onAddPlaceTap: () => _openPlaceSheet(),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () => _openSheet(),
                          icon: const Icon(Icons.add_rounded, size: 22),
                          label: Text(
                            filterPlace == null
                                ? AppStrings.newReminder
                                : '${AppStrings.newReminder} til ${filterPlace.name}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: pal.accent,
                            foregroundColor: pal.onAccent,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onFix;

  const _PermissionBanner({
    required this.title,
    required this.message,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3A2C1C) : const Color(0xFFFBEBD9);
    final border = isDark ? const Color(0xFF5C4426) : const Color(0xFFEBCFAE);
    final fg = isDark ? const Color(0xFFF0C99A) : const Color(0xFF6B4220);
    final button = isDark ? const Color(0xFFE0A866) : const Color(0xFF8A5526);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: button),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.label
                        .copyWith(color: fg, fontWeight: FontWeight.w600)),
                Text(message, style: AppTypography.caption.copyWith(color: fg)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onFix,
            style: FilledButton.styleFrom(
              backgroundColor: button,
              foregroundColor: isDark ? Colors.black : Colors.white,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Ret det'),
          ),
        ],
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  final Reminder reminder;
  final String icon;
  final VoidCallback onReuse;
  final VoidCallback onDelete;

  const _CompletedRow({
    required this.reminder,
    required this.icon,
    required this.onReuse,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dismissible(
      key: ValueKey('done_${reminder.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
            color: AppColors.destructive, borderRadius: AppRadius.roundedMd),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
          borderRadius: AppRadius.roundedMd,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reminder.title,
                style: AppTypography.body.copyWith(
                  color: textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            TextButton(onPressed: onReuse, child: const Text('Brug igen')),
          ],
        ),
      ),
    );
  }
}
