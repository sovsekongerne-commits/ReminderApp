import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../domain/models/place.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';

class CreatePlaceSheet extends StatefulWidget {
  final Place? existingPlace;

  /// Start med "Brug nuværende placering" (bruges af "Jeg er her nu").
  final bool startWithCurrentLocation;

  /// Vises som "Slet sted", når et eksisterende sted rettes.
  final VoidCallback? onDelete;

  const CreatePlaceSheet({
    super.key,
    this.existingPlace,
    this.startWithCurrentLocation = false,
    this.onDelete,
  });

  @override
  State<CreatePlaceSheet> createState() => _CreatePlaceSheetState();
}

class _CreatePlaceSheetState extends State<CreatePlaceSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  late String _selectedIcon;
  double _radiusMeters = 150.0;
  double _latitude = 55.6761;
  double _longitude = 12.5683;
  bool _isLoadingGps = false;

  // 0 = Søg adresse (kan gøres hjemmefra), 1 = Brug nuværende GPS
  int _locationMode = 0;
  bool _isSearching = false;
  List<GeocodingResult> _searchResults = [];
  String? _selectedAddressTitle;
  Timer? _debounceTimer;

  static const List<String> _availableIcons = [
    '🏠',
    '💼',
    '🛒',
    '🏋️',
    '💊',
    '📦',
    '☕',
    '🚗',
    '🌲',
    '👶',
    '🏫',
    '🏥',
    '🍽️',
    '✈️',
    '🚲',
    '⛽',
    '📚',
    '🐕',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingPlace?.name ?? '',
    );
    _searchController = TextEditingController();
    _selectedIcon = widget.existingPlace?.icon ?? _availableIcons.first;
    _radiusMeters = widget.existingPlace?.radiusMeters ?? 150.0;

    if (widget.existingPlace == null && widget.startWithCurrentLocation) {
      _locationMode = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchCurrentLocation();
      });
    }

    if (widget.existingPlace != null) {
      _latitude = widget.existingPlace!.latitude;
      _longitude = widget.existingPlace!.longitude;
      _selectedAddressTitle = widget.existingPlace!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    final service = NativeLocationService();
    final pos = await service.getCurrentLocation();
    if (mounted && pos != null) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _selectedAddressTitle = 'Din nuværende GPS-placering';
        _isLoadingGps = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingGps = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;

    setState(() => _isSearching = true);
    final results = await GeocodingService().searchPlaces(trimmed);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    AppHaptics.selection();
    FocusScope.of(context).unfocus();
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _selectedAddressTitle = '${result.name} (${result.address})';
      _searchResults = [];
      _searchController.text = result.name;

      // Hvis brugeren endnu ikke har skrevet et navn til stedet, udfylder vi automatisk
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = result.name;
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    AppHaptics.medium();

    final place = Place(
      id: widget.existingPlace?.id ?? const Uuid().v4(),
      name: name,
      latitude: _latitude,
      longitude: _longitude,
      icon: _selectedIcon,
      radiusMeters: _radiusMeters,
      createdAt: widget.existingPlace?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingPlace != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkTextMuted.withValues(alpha: 0.3)
                          : AppColors.lightTextMuted.withValues(alpha: 0.4),
                      borderRadius: AppRadius.roundedPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Overskrift
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Rediger sted' : AppStrings.newPlace,
                      style: AppTypography.headline.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Stedets navn
                TextField(
                  controller: _nameController,
                  autofocus: !isEditing && _nameController.text.isEmpty,
                  textInputAction: TextInputAction.next,
                  style: AppTypography.title.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.placeNameHint,
                    prefixIcon: Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text(
                        _selectedIcon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),

                // VÆLG METODE: SØG ADRESSE HJEMMEFRA ELLER BRUG GPS
                Text(
                  'HVOR LIGGER STEDET?'.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSubtle
                        : AppColors.lightSurfaceSubtle,
                    borderRadius: AppRadius.roundedPill,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() => _locationMode = 0);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _locationMode == 0
                                  ? (isDark
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: AppRadius.roundedPill,
                              boxShadow: _locationMode == 0 && !isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🔍 ', style: TextStyle(fontSize: 14)),
                                Flexible(
                                  child: Text(
                                    'Søg adresse',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label.copyWith(
                                      color: _locationMode == 0
                                          ? (isDark
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.primary)
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                      fontWeight: _locationMode == 0
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() => _locationMode = 1);
                            _fetchCurrentLocation();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _locationMode == 1
                                  ? (isDark
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: AppRadius.roundedPill,
                              boxShadow: _locationMode == 1 && !isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📍 ', style: TextStyle(fontSize: 14)),
                                Flexible(
                                  child: Text(
                                    'Min placering',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label.copyWith(
                                      color: _locationMode == 1
                                          ? (isDark
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.primary)
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                      fontWeight: _locationMode == 1
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 4),

                // HVIS MODE 0: SØGEFELT
                if (_locationMode == 0) ...[
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: _performSearch,
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Søg f.eks. "Nørregade 10", "Bilka", eller by...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _isSearching = false;
                                    });
                                  },
                                )
                              : null,
                    ),
                  ),

                  // SØGERESULTATER
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSubtle
                            : AppColors.lightSurfaceSubtle,
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Text('📍', style: TextStyle(fontSize: 18)),
                            title: Text(
                              item.name,
                              style: AppTypography.label.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              item.address,
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                  ],
                ],

                // HVIS MODE 1: NUVÆRENDE GPS
                if (_locationMode == 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSubtle
                          : AppColors.lightSurfaceSubtle,
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: _isLoadingGps
                              ? Theme.of(context).colorScheme.primary
                              : (isDark
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _isLoadingGps
                                ? 'Henter din GPS-position...'
                                : 'Aktuel GPS fundet (${_latitude.toStringAsFixed(3)}, ${_longitude.toStringAsFixed(3)})',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (!_isLoadingGps)
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            onPressed: _fetchCurrentLocation,
                            color: isDark
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ],

                // VISNING AF VALGT ADRESSE / PLACERING
                if (_selectedAddressTitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isDark
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🌸 ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            'Sat til: $_selectedAddressTitle',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // IKONVÆLGER
                Text(
                  AppStrings.placeIconLabel.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () {
                          AppHaptics.selection();
                          setState(() => _selectedIcon = icon);
                        },
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isDark
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12))
                                : (isDark
                                    ? AppColors.darkSurfaceSubtle
                                    : AppColors.lightSurfaceSubtle),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // GEOFENCE RADIUS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.placeRadiusLabel.toUpperCase(),
                      style: AppTypography.micro.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${_radiusMeters.round()} meter',
                      style: AppTypography.label.copyWith(
                        color: isDark
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Slider(
                  value: _radiusMeters,
                  min: 50,
                  max: 500,
                  divisions: 9,
                  activeColor: isDark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary,
                  inactiveColor: isDark
                      ? AppColors.darkSurfaceSubtle
                      : AppColors.lightSurfaceSubtle,
                  onChanged: (val) {
                    setState(() => _radiusMeters = val);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // GEM KNAP
                FilledButton(
                  onPressed: _nameController.text.trim().isEmpty ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor: isDark
                        ? AppColors.darkSurfaceSubtle
                        : AppColors.lightSurfaceSubtle,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedMd,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Opdater sted' : AppStrings.savePlace,
                    style: AppTypography.title.copyWith(
                      color: _nameController.text.trim().isEmpty
                          ? null
                          : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isEditing && widget.onDelete != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDelete!();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Slet sted'),
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
