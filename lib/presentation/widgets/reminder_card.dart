import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/day_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/repositories/item_history_repository.dart';
import '../../domain/models/reminder.dart';
import '../providers/reminder_provider.dart';

/// Et kort med en huskeseddel.
/// - Swipe til højre: udført. Swipe til venstre: slet.
/// - Tryk på titlen: ret sedlen.
/// - Skriv i "+ Tilføj…" og tryk Enter for at tilføje et punkt.
class ReminderCard extends ConsumerStatefulWidget {
  final Reminder reminder;

  /// Stedet kortet vises under (kortet kan stå under flere steder).
  final String? groupPlaceId;

  /// Navne på sedlens andre steder ("Også ved …").
  final List<String> otherPlaceNames;

  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<String> onToggleItem;
  final ValueChanged<String> onAddItem;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.groupPlaceId,
    this.otherPlaceNames = const [],
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleItem,
    required this.onAddItem,
  });

  @override
  ConsumerState<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends ConsumerState<ReminderCard> {
  final _addController = TextEditingController();
  final _addFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _addController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final text = (value ?? _addController.text).trim();
    if (text.isEmpty) return;
    AppHaptics.light();
    widget.onAddItem(text);
    _addController.clear();
    // Behold fokus, så man kan skrive næste punkt med det samme
    _addFocus.requestFocus();
  }

  void _showImage(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: ClipRRect(
            borderRadius: AppRadius.roundedLg,
            child: kIsWeb
                ? Image.network(path, fit: BoxFit.contain)
                : Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pal = DayPalette.current(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final history = ref.watch(itemHistoryProvider);
    final suggestions = ItemHistoryRepository.suggest(
      history,
      _addController.text,
      exclude: r.checklistItems.map((i) => i.text).toList(),
    );

    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, AppSpacing.md, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Udført-cirkel
          IconButton(
            key: const Key('completion_checkbox'),
            tooltip: 'Markér som udført',
            onPressed: () {
              AppHaptics.light();
              widget.onComplete();
            },
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderStrong
                      : const Color(0xFFBDB1A3),
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel – tryk for at rette
                  InkWell(
                    borderRadius: AppRadius.roundedSm,
                    onTap: () {
                      AppHaptics.light();
                      widget.onEdit();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        r.title,
                        style: AppTypography.title.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Punkter
                  if (r.hasItems) ...[
                    const SizedBox(height: 4),
                    for (final item in r.checklistItems)
                      InkWell(
                        borderRadius: AppRadius.roundedSm,
                        onTap: () {
                          AppHaptics.selection();
                          widget.onToggleItem(item.id);
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: AppDurations.fast,
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: item.isDone
                                      ? const Color(0xFF5E875E)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.isDone
                                        ? const Color(0xFF5E875E)
                                        : const Color(0xFFBDB1A3),
                                    width: 1.8,
                                  ),
                                ),
                                child: item.isDone
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: AppTypography.body.copyWith(
                                    color: item.isDone
                                        ? textSecondary
                                        : textPrimary,
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],

                  // Tilføj direkte på kortet
                  TextField(
                    controller: _addController,
                    focusNode: _addFocus,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _submit,
                    style: AppTypography.body.copyWith(color: textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      hintText: '+ Tilføj…',
                      hintStyle:
                          AppTypography.body.copyWith(color: textSecondary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: pal.accent),
                      ),
                      suffixIcon: _addController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Tilføj',
                              icon: Icon(Icons.add_circle_rounded,
                                  color: pal.accent),
                              onPressed: _submit,
                            ),
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in suggestions)
                            ActionChip(
                              label: Text(s),
                              onPressed: () => _submit(s),
                              backgroundColor: pal.soft,
                              side: BorderSide(color: pal.line),
                              labelStyle: AppTypography.label
                                  .copyWith(color: pal.softInk),
                              shape: const StadiumBorder(),
                            ),
                        ],
                      ),
                    ),

                  // Billede
                  if (r.imagePath != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showImage(r.imagePath!),
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedMd,
                        child: SizedBox(
                          width: 120,
                          height: 80,
                          child: kIsWeb
                              ? Image.network(r.imagePath!, fit: BoxFit.cover)
                              : Image.file(File(r.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox()),
                        ),
                      ),
                    ),
                  ],

                  // Mærker
                  if (r.afterLabel != null ||
                      r.isRecurring ||
                      widget.otherPlaceNames.isNotEmpty ||
                      r.hasItems) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (r.afterLabel != null)
                          _Tag(
                            text: 'Efter kl. ${r.afterLabel}',
                            bg: isDark
                                ? const Color(0xFF3A2E22)
                                : const Color(0xFFFCF0E3),
                            fg: isDark
                                ? const Color(0xFFE8BE8E)
                                : const Color(0xFF8A5526),
                          ),
                        if (r.isRecurring)
                          _Tag(
                            text: 'Hver gang',
                            icon: Icons.repeat_rounded,
                            bg: isDark
                                ? const Color(0xFF26332A)
                                : const Color(0xFFE4EDE2),
                            fg: isDark
                                ? const Color(0xFFA9CFA9)
                                : const Color(0xFF3F5E3E),
                          ),
                        if (widget.otherPlaceNames.isNotEmpty)
                          _Tag(
                            text:
                                'Også ved ${widget.otherPlaceNames.join(' og ')}',
                            bg: isDark
                                ? const Color(0xFF262A36)
                                : const Color(0xFFEEF0F5),
                            fg: isDark
                                ? const Color(0xFFB6C0DA)
                                : const Color(0xFF45506B),
                          ),
                        if (r.hasItems)
                          _Tag(
                            text:
                                '${r.doneCount} af ${r.checklistItems.length}',
                            bg: isDark
                                ? AppColors.darkSurfaceSubtle
                                : AppColors.lightSurfaceSubtle,
                            fg: textSecondary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('${r.id}_${widget.groupPlaceId ?? 'none'}'),
      direction: DismissDirection.horizontal,
      background: _SwipeBg(
        color: const Color(0xFF5E875E),
        icon: Icons.check_rounded,
        label: 'Udført',
        alignLeft: true,
      ),
      secondaryBackground: const _SwipeBg(
        color: AppColors.destructive,
        icon: Icons.delete_outline_rounded,
        label: 'Slet',
        alignLeft: false,
      ),
      confirmDismiss: (direction) async {
        AppHaptics.medium();
        if (direction == DismissDirection.startToEnd) {
          widget.onComplete();
          // Faste sedler bliver stående (de nulstilles bare)
          return !r.isRecurring;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) widget.onDelete();
      },
      child: card,
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;

  const _Tag({required this.text, this.icon, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppTypography.caption.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool alignLeft;

  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 6),
        Text(label,
            style: AppTypography.label.copyWith(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.roundedLg),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: content,
    );
  }
}
