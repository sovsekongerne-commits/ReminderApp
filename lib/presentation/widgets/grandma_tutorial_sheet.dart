import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';

class GrandmaTutorialSheet extends StatefulWidget {
  final VoidCallback onSampleReminderRequested;

  const GrandmaTutorialSheet({
    super.key,
    required this.onSampleReminderRequested,
  });

  @override
  State<GrandmaTutorialSheet> createState() => _GrandmaTutorialSheetState();
}

class _GrandmaTutorialSheetState extends State<GrandmaTutorialSheet> {
  int _currentStep = 0;

  final List<
    ({
      String icon,
      String title,
      String description,
      Color pastelColor,
      Color textColor,
    })
  >
  _steps = [
    (
      icon: '🌸',
      title: 'Velkommen til din hjælper',
      description: 'Her hjælper telefonen dig med at huske de små ting i hverdagen – helt automatisk, så du slipper for bekymringer.',
      pastelColor: AppColors.accentSubtleLight,
      textColor: AppColors.accent,
    ),
    (
      icon: '🏠',
      title: 'Dine faste steder',
      description: 'Hjem og Arbejde ligger klar nederst. Tryk på plusset for at tilføje dine egne steder, f.eks. Netto, Apoteket eller Mormor.',
      pastelColor: AppColors.pastelPeach,
      textColor: AppColors.pastelPeachText,
    ),
    (
      icon: '✍️',
      title: 'Så let er det',
      description: 'Tryk på knappen forneden og skriv, hvad du vil huske. Tilføj gerne punkter, f.eks. mælk, brød og kaffe.',
      pastelColor: AppColors.pastelSage,
      textColor: AppColors.pastelSageText,
    ),
    (
      icon: '🔔',
      title: 'Et kærligt prik',
      description: 'Telefonen giver dig en venlig besked, lige når du ankommer. Tryk på beskeden, så får du listen i store bogstaver.',
      pastelColor: AppColors.pastelLavender,
      textColor: AppColors.pastelLavenderText,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _steps[_currentStep];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lille træk-streg i toppen
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkTextMuted.withValues(alpha: 0.3)
                        : AppColors.lightTextMuted.withValues(alpha: 0.4),
                    borderRadius: AppRadius.roundedPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Trin-indikator i pastelfarver
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  return AnimatedContainer(
                    duration: AppDurations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary)
                          : (isDark
                                ? AppColors.darkSurfaceSubtle
                                : AppColors.lightSurfaceSubtle),
                      borderRadius: AppRadius.roundedPill,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Hovedkort med stort ikon og mormor-forklaring
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: Container(
                  key: ValueKey(_currentStep),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSubtle
                        : step.pastelColor,
                    borderRadius: AppRadius.roundedXl,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(step.icon, style: const TextStyle(fontSize: 54)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        step.title,
                        style: AppTypography.headline.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        step.description,
                        style: AppTypography.body.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextPrimary.withValues(
                                  alpha: 0.8,
                                ),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Handlingsknapper
              if (_currentStep < _steps.length - 1)
                FilledButton(
                  onPressed: () {
                    AppHaptics.light();
                    setState(() {
                      _currentStep++;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedPill,
                    ),
                  ),
                  child: Text(
                    'Næste trin 🌸',
                    style: AppTypography.title.copyWith(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              else ...[
                FilledButton(
                  onPressed: () {
                    AppHaptics.medium();
                    Navigator.of(context).pop();
                    widget.onSampleReminderRequested();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedPill,
                    ),
                  ),
                  child: Text(
                    'Lav en nem prøve-påmindelse for mig 🌸',
                    style: AppTypography.title.copyWith(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Jeg forstår det, tak!',
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
