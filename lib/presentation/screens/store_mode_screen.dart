import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/day_palette.dart';
import '../../core/utils/haptics.dart';
import '../../domain/models/reminder.dart';
import '../providers/place_provider.dart';
import '../providers/reminder_provider.dart';

/// Butikstilstand: kun listen for ét sted, store felter, skærmen holdes
/// tændt. Når alt er krydset af, vises en kort afslutning.
///
/// Lukkes med en besked til forsiden (vises som en lille bjælke), eller null.
class StoreModeScreen extends ConsumerStatefulWidget {
  final String placeId;

  /// Vis kun disse sedler (bruges for sedler med flere steder).
  final List<String>? reminderIds;

  /// Overskrift i stedet for stedets navn.
  final String? title;

  const StoreModeScreen({
    super.key,
    required this.placeId,
    this.reminderIds,
    this.title,
  });

  bool shows(Reminder r) =>
      !r.isCompleted &&
      (reminderIds == null ? r.isAt(placeId) : reminderIds!.contains(r.id));

  @override
  ConsumerState<StoreModeScreen> createState() => _StoreModeScreenState();
}

class _StoreModeScreenState extends ConsumerState<StoreModeScreen> {
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  Future<void> _finish() async {
    final reminders = ref.read(remindersProvider);
    final notes = reminders.where(widget.shows).toList();
    final anyRecurringDone = notes.any((r) => r.isRecurring && r.allItemsDone);
    final anyOneOffDone = notes.any((r) => !r.isRecurring && r.allItemsDone);
    await ref
        .read(remindersProvider.notifier)
        .finishReminders(notes.map((r) => r.id).toList());
    if (!mounted) return;
    String? msg;
    if (anyOneOffDone) {
      msg = 'Alt er klaret – sedlen er flyttet til udførte';
    } else if (anyRecurringDone) {
      msg = 'Alt er klaret – listen er klar til næste gang';
    }
    Navigator.of(context).pop(msg);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pal = DayPalette.current(context);
    final place = ref.watch(placesProvider.select(
        (ps) => ps.where((p) => p.id == widget.placeId).firstOrNull));
    final notes = ref
        .watch(remindersProvider)
        .where(widget.shows)
        .toList();

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final withItems = notes.where((r) => r.hasItems).toList();
    final allDone =
        withItems.isNotEmpty && withItems.every((r) => r.allItemsDone);

    if (allDone && !_celebrated) {
      _celebrated = true;
      HapticFeedback.heavyImpact();
    } else if (!allDone) {
      _celebrated = false;
    }

    final recurringOnly = withItems.isNotEmpty && withItems.every((r) => r.isRecurring);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: pal.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: allDone
                ? _Celebration(
                    key: const ValueKey('done'),
                    text: recurringOnly
                        ? 'Listen er klar igen, næste gang du kommer forbi.'
                        : 'Sedlen flyttes til udførte.',
                    onDone: _finish,
                  )
                : Column(
                    key: const ValueKey('list'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Tilbage',
                              iconSize: 28,
                              icon: Icon(Icons.chevron_left_rounded,
                                  color: textPrimary),
                              onPressed: _finish,
                            ),
                            Text(place?.icon ?? '📍',
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title ?? place?.name ?? '',
                                style: AppTypography.headline.copyWith(
                                    color: textPrimary, fontSize: 26),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 20),
                          children: [
                            if (notes.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: Text('Intet at huske her 🌸',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.title
                                        .copyWith(color: textSecondary)),
                              ),
                            for (final r in notes) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Text(r.title,
                                        style: AppTypography.headline.copyWith(
                                            color: textPrimary,
                                            fontSize: 21,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  if (r.hasItems)
                                    Text('${r.doneCount} af ${r.checklistItems.length}',
                                        style: AppTypography.body
                                            .copyWith(color: textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              for (final item in r.checklistItems)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: item.isDone
                                        ? (isDark
                                            ? AppColors.darkSurfaceSubtle
                                            : const Color(0xFFF0EBE4))
                                        : (isDark
                                            ? AppColors.darkSurface
                                            : AppColors.lightSurface),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.roundedLg,
                                      side: BorderSide(
                                          color: item.isDone
                                              ? Colors.transparent
                                              : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.lightBorder)),
                                    ),
                                    child: InkWell(
                                      borderRadius: AppRadius.roundedLg,
                                      onTap: () {
                                        AppHaptics.selection();
                                        ref
                                            .read(remindersProvider.notifier)
                                            .toggleItem(r.id, item.id,
                                                autoComplete: false);
                                      },
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(minHeight: 66),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              AnimatedContainer(
                                                duration: AppDurations.fast,
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: item.isDone
                                                      ? const Color(0xFF5E875E)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                  border: Border.all(
                                                    color: item.isDone
                                                        ? const Color(0xFF5E875E)
                                                        : const Color(0xFFBDB1A3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: item.isDone
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 24)
                                                    : null,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  item.text,
                                                  style: TextStyle(
                                                    fontSize: 21,
                                                    color: item.isDone
                                                        ? textSecondary
                                                        : textPrimary,
                                                    decoration: item.isDone
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
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
                              if (!r.hasItems)
                                FilledButton.tonal(
                                  onPressed: () {
                                    AppHaptics.medium();
                                    ref
                                        .read(remindersProvider.notifier)
                                        .complete(r.id);
                                  },
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(64),
                                    backgroundColor: isDark
                                        ? const Color(0xFF26332A)
                                        : const Color(0xFFE4EDE2),
                                    foregroundColor: isDark
                                        ? const Color(0xFFA9CFA9)
                                        : const Color(0xFF3F5E3E),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.roundedLg),
                                  ),
                                  child: const Text('Klaret',
                                      style: TextStyle(fontSize: 18)),
                                ),
                              const SizedBox(height: 24),
                            ],
                            Row(
                              children: [
                                Icon(Icons.stay_current_portrait_rounded,
                                    size: 16, color: textSecondary),
                                const SizedBox(width: 6),
                                Text('Skærmen holdes tændt, mens listen er åben',
                                    style: AppTypography.caption
                                        .copyWith(color: textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: FilledButton(
                          onPressed: _finish,
                          style: FilledButton.styleFrom(
                            backgroundColor: textPrimary,
                            foregroundColor:
                                isDark ? AppColors.darkBackground : Colors.white,
                            minimumSize: const Size.fromHeight(58),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Færdig',
                              style: TextStyle(fontSize: 17)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Celebration extends StatefulWidget {
  final String text;
  final VoidCallback onDone;

  const _Celebration({
    super.key,
    required this.text,
    required this.onDone,
  });

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final pop = CurvedAnimation(
        parent: _c, curve: const Interval(0, 0.7, curve: Curves.elasticOut));
    final rise = CurvedAnimation(
        parent: _c, curve: const Interval(0.4, 1, curve: Curves.easeOut));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: pop,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E875E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5E875E).withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 72),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: rise,
              child: Column(
                children: [
                  Text('Alt er klaret',
                      style: AppTypography.display.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(widget.text,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: textSecondary)),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: widget.onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: textPrimary,
                      foregroundColor:
                          isDark ? AppColors.darkBackground : Colors.white,
                      minimumSize: const Size(220, 56),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Færdig', style: TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
