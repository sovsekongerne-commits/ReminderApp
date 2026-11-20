import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/day_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/repositories/item_history_repository.dart';
import '../../domain/models/place.dart';
import '../../domain/models/reminder.dart';
import '../providers/reminder_provider.dart';

/// Ét enkelt ark til at oprette eller rette en seddel:
/// titel, valgfrie punkter, valgfrit billede, et eller flere steder,
/// valgfrit klokkeslæt og "Mind mig hver gang".
class CreateReminderSheet extends ConsumerStatefulWidget {
  final List<Place> places;
  final Reminder? existingReminder;
  final String? preselectedPlaceId;
  final List<String> presetItems;
  final ValueChanged<Reminder> onReminderSaved;
  final VoidCallback? onDelete;

  /// Åbner "nyt sted" med den nuværende placering. Returnerer det nye sted.
  final Future<Place?> Function() onCreatePlaceHere;

  const CreateReminderSheet({
    super.key,
    required this.places,
    this.existingReminder,
    this.preselectedPlaceId,
    this.presetItems = const [],
    required this.onReminderSaved,
    this.onDelete,
    required this.onCreatePlaceHere,
  });

  @override
  ConsumerState<CreateReminderSheet> createState() =>
      _CreateReminderSheetState();
}

class _CreateReminderSheetState extends ConsumerState<CreateReminderSheet> {
  final _titleController = TextEditingController();
  final _itemController = TextEditingController();
  final _itemFocus = FocusNode();

  late List<ChecklistItem> _items;
  late List<Place> _places;
  late Set<String> _placeIds;
  String? _imagePath;
  int? _afterMinutes;
  bool _recurring = false;

  bool get _isEditing => widget.existingReminder != null;

  @override
  void initState() {
    super.initState();
    _places = List.of(widget.places);
    final r = widget.existingReminder;
    if (r != null) {
      _titleController.text = r.title;
      _items = List.of(r.checklistItems);
      _placeIds = r.placeIds.toSet();
      _imagePath = r.imagePath;
      _afterMinutes = r.afterMinutes;
      _recurring = r.isRecurring;
    } else {
      _items = [
        for (final t in widget.presetItems)
          ChecklistItem(id: const Uuid().v4(), text: t),
      ];
      final pre = widget.preselectedPlaceId ??
          (_places.isNotEmpty ? _places.first.id : null);
      _placeIds = {if (pre != null) pre};
    }
    _titleController.addListener(() => setState(() {}));
    _itemController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _itemController.dispose();
    _itemFocus.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _placeIds.isNotEmpty &&
      (_titleController.text.trim().isNotEmpty ||
          _items.isNotEmpty ||
          _itemController.text.trim().isNotEmpty);

  void _addItem([String? value]) {
    final text = (value ?? _itemController.text).trim();
    if (text.isEmpty) return;
    AppHaptics.selection();
    setState(() {
      _items.add(ChecklistItem(id: const Uuid().v4(), text: text));
      _itemController.clear();
    });
    ref.read(itemHistoryProvider.notifier).remember(text);
    _itemFocus.requestFocus();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tag et foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Vælg fra galleri'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imagePath = picked.path);
      }
    } catch (e) {
      debugPrint('Fejl ved valg af billede: $e');
    }
  }

  Future<void> _pickTime() async {
    final initial = _afterMinutes == null
        ? const TimeOfDay(hour: 16, minute: 0)
        : TimeOfDay(hour: _afterMinutes! ~/ 60, minute: _afterMinutes! % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() => _afterMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _placeHere() async {
    final place = await widget.onCreatePlaceHere();
    if (place != null && mounted) {
      setState(() {
        _places = [..._places, place];
        _placeIds.add(place.id);
      });
    }
  }

  void _save() {
    if (!_canSave) return;
    final items = List.of(_items);
    final pending = _itemController.text.trim();
    if (pending.isNotEmpty) {
      items.add(ChecklistItem(id: const Uuid().v4(), text: pending));
      ref.read(itemHistoryProvider.notifier).remember(pending);
    }
    var title = _titleController.text.trim();
    if (title.isEmpty) title = items.isNotEmpty ? items.first.text : 'Huskeseddel';

    AppHaptics.medium();
    final old = widget.existingReminder;
    final reminder = Reminder(
      id: old?.id ?? const Uuid().v4(),
      title: title,
      // Bevar rækkefølgen fra stedbjælken
      placeIds: [
        for (final p in _places)
          if (_placeIds.contains(p.id)) p.id,
      ],
      checklistItems: items,
      imagePath: _imagePath,
      afterMinutes: _afterMinutes,
      isRecurring: _recurring,
      enabled: old?.enabled ?? true,
      createdAt: old?.createdAt ?? DateTime.now(),
      completedAt: old?.completedAt,
    );
    widget.onReminderSaved(reminder);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pal = DayPalette.current(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final history = ref.watch(itemHistoryProvider);
    final exclude = _items.map((i) => i.text).toList();
    final typed = _itemController.text.trim();
    // Mens man skriver: ord man har brugt før. Ellers: de senest brugte.
    final suggestions = typed.isNotEmpty
        ? ItemHistoryRepository.suggest(history, typed, exclude: exclude)
        : history
            .where((w) => !exclude
                .map((e) => e.toLowerCase())
                .contains(w.toLowerCase()))
            .take(5)
            .toList();

    Widget sectionLabel(String text, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: text,
                style: AppTypography.micro.copyWith(color: textSecondary),
              ),
              if (hint != null)
                TextSpan(
                  text: '  ·  $hint',
                  style: AppTypography.caption.copyWith(color: textSecondary),
                ),
            ]),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: pal.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: AppRadius.roundedPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? AppStrings.editReminder
                            : AppStrings.newReminder,
                        style: AppTypography.headline
                            .copyWith(color: textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.cancel,
                          style: TextStyle(color: textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // HVAD
                sectionLabel('HVAD SKAL DU HUSKE?'),
                TextField(
                  controller: _titleController,
                  autofocus: !_isEditing && widget.presetItems.isEmpty,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium.copyWith(
                      color: textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: AppStrings.reminderInputHint,
                    fillColor: surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // PUNKTER
                for (final item in _items)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFBDB1A3), width: 1.6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.text,
                              style: AppTypography.body
                                  .copyWith(color: textPrimary)),
                        ),
                        IconButton(
                          tooltip: 'Fjern punkt',
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: textSecondary),
                          onPressed: () => setState(() => _items.remove(item)),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _itemController,
                  focusNode: _itemFocus,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _addItem,
                  style: AppTypography.body.copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: '+ Tilføj punkt (tryk Enter)',
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedMd,
                      borderSide: BorderSide(color: border),
                    ),
                    suffixIcon: typed.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Tilføj',
                            icon: Icon(Icons.add_circle_rounded,
                                color: pal.accent),
                            onPressed: _addItem,
                          ),
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in suggestions)
                        ActionChip(
                          label: Text('+ $s'),
                          onPressed: () => _addItem(s),
                          backgroundColor: pal.soft,
                          side: BorderSide(color: pal.line),
                          labelStyle:
                              AppTypography.label.copyWith(color: pal.softInk),
                          shape: const StadiumBorder(),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // BILLEDE
                if (_imagePath == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Tilføj billede'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: border),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.roundedMd),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.roundedMd,
                        child: SizedBox(
                          width: 96,
                          height: 64,
                          child: kIsWeb
                              ? Image.network(_imagePath!, fit: BoxFit.cover)
                              : Image.file(File(_imagePath!), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () => setState(() => _imagePath = null),
                        child: const Text('Fjern billede'),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),

                // HVOR
                sectionLabel('NÅR JEG KOMMER TIL', hint: 'vælg et eller flere'),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final p in _places)
                      FilterChip(
                        label: Text('${p.icon} ${p.name}'),
                        selected: _placeIds.contains(p.id),
                        showCheckmark: false,
                        onSelected: (sel) {
                          AppHaptics.selection();
                          setState(() {
                            if (sel) {
                              _placeIds.add(p.id);
                            } else {
                              _placeIds.remove(p.id);
                            }
                          });
                        },
                        selectedColor: textPrimary,
                        backgroundColor: surface,
                        labelStyle: AppTypography.label.copyWith(
                          fontSize: 14,
                          color: _placeIds.contains(p.id)
                              ? (isDark ? AppColors.darkBackground : Colors.white)
                              : textPrimary,
                        ),
                        side: BorderSide(
                            color: _placeIds.contains(p.id)
                                ? textPrimary
                                : border),
                        shape: const StadiumBorder(),
                      ),
                    ActionChip(
                      avatar: Icon(Icons.my_location_rounded,
                          size: 16, color: pal.accent),
                      label: const Text('Jeg er her nu'),
                      onPressed: _placeHere,
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: pal.accent),
                      labelStyle: AppTypography.label
                          .copyWith(color: pal.accent, fontSize: 14),
                      shape: const StadiumBorder(),
                    ),
                  ],
                ),
                if (_placeIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Vælg mindst ét sted',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.destructive)),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // TID + FAST
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: AppRadius.roundedLg,
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Klokkeslæt',
                            style: AppTypography.body
                                .copyWith(color: textPrimary)),
                        subtitle: Text(
                          _afterMinutes == null
                              ? 'Hele dagen'
                              : 'Kun efter kl. ${Reminder.formatMinutes(_afterMinutes!)}',
                          style: AppTypography.caption
                              .copyWith(color: textSecondary),
                        ),
                        trailing: _afterMinutes == null
                            ? TextButton(
                                onPressed: _pickTime,
                                child: const Text('Vælg tid'))
                            : IconButton(
                                tooltip: 'Fjern tid',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () =>
                                    setState(() => _afterMinutes = null),
                              ),
                        onTap: _pickTime,
                      ),
                      Divider(height: 1, color: border),
                      SwitchListTile(
                        value: _recurring,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _recurring = v);
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF5E875E),
                        title: Text('Mind mig hver gang',
                            style: AppTypography.body
                                .copyWith(color: textPrimary)),
                        subtitle: Text(
                          'Fluebenene nulstilles ved næste ankomst',
                          style: AppTypography.caption
                              .copyWith(color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: pal.accent,
                    foregroundColor: pal.onAccent,
                    minimumSize: const Size.fromHeight(54),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    _isEditing ? AppStrings.updateReminder : AppStrings.saveReminder,
                    style: AppTypography.title.copyWith(
                        color: _canSave ? pal.onAccent : null,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (_isEditing && widget.onDelete != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDelete!();
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        minimumSize: const Size.fromHeight(44)),
                    child: const Text('Slet seddel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
