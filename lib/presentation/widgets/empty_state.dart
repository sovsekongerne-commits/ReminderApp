import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';

class EmptyRemindersView extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onAddTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onTestNotification;

  const EmptyRemindersView({
    super.key,
    this.isFiltered = false,
    this.onAddTap,
    this.onTutorialTap,
    this.onTestNotification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.roundedXl,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSubtle
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isFiltered ? '🔍' : '🌸',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isFiltered
                    ? AppStrings.noFilteredReminders
                    : AppStrings.noActiveReminders,
                style: AppTypography.title.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isFiltered
                    ? 'Vælg et andet sted nederst, eller opret en ny seddel.'
                    : AppStrings.noActiveRemindersSub,
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isFiltered) ...[
                const SizedBox(height: AppSpacing.lg),
                if (onTutorialTap != null)
                  FilledButton.icon(
                    onPressed: () {
                      AppHaptics.light();
                      onTutorialTap!();
                    },
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('Se den nemme vejledning'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: isDark
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedPill,
                        side: BorderSide(
                          color: isDark
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (onTestNotification != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: () {
                      AppHaptics.medium();
                      onTestNotification!();
                    },
                    icon: const Icon(Icons.notifications_active_outlined, size: 16),
                    label: const Text('Prøv en notifikation på din telefon 🔔'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
