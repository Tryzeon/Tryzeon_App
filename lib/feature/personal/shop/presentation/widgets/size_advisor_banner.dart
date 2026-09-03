import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/presentation/mappers/fit_result_ui_mapper.dart';

class SizeAdvisorBanner extends StatelessWidget {
  const SizeAdvisorBanner({super.key, required this.fitResult});

  final FitResult fitResult;

  @override
  Widget build(final BuildContext context) {
    final state = fitResult.displayState;
    if (state == FitDisplayState.unknown) return const SizedBox.shrink();
    if (state == FitDisplayState.noUserData) return const _NoUserDataBanner();

    final (Color color, Color onContainer) = switch (state) {
      FitDisplayState.match => (AppColors.fitMatch, AppColors.onFitMatchContainer),
      FitDisplayState.caveats => (AppColors.fitCaveat, AppColors.onFitCaveatContainer),
      FitDisplayState.outOfRange => (
        AppColors.fitOutOfRange,
        AppColors.onFitOutOfRangeContainer,
      ),
      _ => throw StateError('handled above'),
    };

    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: color),
        borderRadius: AppRadius.cardAll,
      ),
      child: Row(
        children: [
          Icon(fitResult.iconData, color: color, size: 20),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fitResult.headline,
                  style: textTheme.titleSmall?.copyWith(
                    color: onContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fitResult.subline,
                  style: textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft prompt, deliberately lighter than the other states: it skips
/// [_BannerShell] in favor of a single tappable row.
class _NoUserDataBanner extends StatelessWidget {
  const _NoUserDataBanner();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.cardAll,
        onTap: () => context.push(AppRoutes.personalSettingsBodyMeasurements),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smMd,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.cardAll,
          ),
          child: Row(
            children: [
              Icon(
                Icons.straighten_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Text(
                  '輸入您的身形即可自動計算合身尺寸呦',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
