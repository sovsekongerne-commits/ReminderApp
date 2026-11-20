import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/day_palette.dart';
import '../../core/utils/haptics.dart';
import '../../domain/models/place.dart';

/// Stederne nederst på skærmen, hvor tommelfingeren er.
/// - Tryk: vis kun det sted.
/// - Hold fingeren på et sted: ret eller slet det.
/// - Plus: nyt sted.
class PlacesBar extends StatelessWidget {
  final List<Place> places;
  final String? selectedPlaceId;
  final Map<String, int> counts;
  final ValueChanged<String?> onPlaceSelected;
  final ValueChanged<Place> onPlaceLongPress;
  final VoidCallback onAddPlaceTap;

  const PlacesBar({
    super.key,
    required this.places,
    required this.selectedPlaceId,
    required this.counts,
    required this.onPlaceSelected,
    required this.onPlaceLongPress,
    required this.onAddPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = DayPalette.current(context);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          // Plus står fast yderst til venstre
          Tooltip(
            message: 'Tilføj nyt sted',
            child: Material(
              color: pal.accent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('add_place_button'),
                customBorder: const CircleBorder(),
                onTap: () {
                  AppHaptics.light();
                  onAddPlaceTap();
                },
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(Icons.add_rounded, color: pal.onAccent, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: AppSpacing.md),
              children: [
                _PlaceChip(
                  label: 'Alle',
                  icon: null,
                  count: 0,
                  selected: selectedPlaceId == null,
                  onTap: () => onPlaceSelected(null),
                ),
                for (final p in places)
                  _PlaceChip(
                    label: p.name,
                    icon: p.icon,
                    count: counts[p.id] ?? 0,
                    selected: selectedPlaceId == p.id,
                    onTap: () => onPlaceSelected(p.id),
                    onLongPress: () => onPlaceLongPress(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  final String label;
  final String? icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PlaceChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pal = DayPalette.current(context);
    final fgSelected = isDark ? AppColors.darkBackground : Colors.white;
    final bgSelected =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: selected
            ? bgSelected
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? bgSelected
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          onLongPress: onLongPress == null
              ? null
              : () {
                  AppHaptics.medium();
                  onLongPress!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Text(icon!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: selected ? fgSelected : fg,
                    fontSize: 14,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? fgSelected : pal.soft,
                      borderRadius: AppRadius.roundedPill,
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.micro.copyWith(
                        color: selected ? bgSelected : pal.softInk,
                        letterSpacing: 0,
                      ),
                    ),
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
