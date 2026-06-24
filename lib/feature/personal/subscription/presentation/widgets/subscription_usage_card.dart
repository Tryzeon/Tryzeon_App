import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';

/// Account-page-only card showing current plan name + a single hero usage
/// stat (today's try-ons). Full per-feature usage breakdown lives on the
/// Subscription page (progressive disclosure — keeps Account page clean and
/// avoids ambient scarcity anxiety).
///
/// For the loading variant use [SubscriptionUsageCardSkeleton] — it mirrors
/// this layout under Skeletonizer so hydration doesn't cause a height jump.
class SubscriptionUsageCard extends StatelessWidget {
  const SubscriptionUsageCard({
    required this.entitlement,
    required this.formattedRenewalLine,
    required this.dailyTryOnUsed,
    required this.dailyTryOnLimit,
    required this.onTap,
    super.key,
  });

  final AppSubscriptionEntitlement entitlement;
  final String? formattedRenewalLine;
  final int? dailyTryOnUsed;
  final int? dailyTryOnLimit;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    planName(entitlement.tier),
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (entitlement.hasActiveSubscription) _ActivePill(),
                ],
              ),
              if (formattedRenewalLine != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formattedRenewalLine!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _UsageStat(label: '今日試穿', used: dailyTryOnUsed, limit: dailyTryOnLimit),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.smMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '查看訂閱詳情',
                    style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layout-only skeleton mirroring [SubscriptionUsageCard]'s structure so the
/// real card swaps in without a height jump. Skeletonizer shimmers over the
/// placeholder text — the strings themselves are arbitrary.
///
/// Kept structurally close to the real card by convention; if [SubscriptionUsageCard]
/// changes shape, update this widget too (covered by golden tests).
class SubscriptionUsageCardSkeleton extends StatelessWidget {
  const SubscriptionUsageCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Skeletonizer(
      child: Card(
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Renewing on YYYY-MM-DD',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('0 / 00', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '今日試穿',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(height: 2, color: colorScheme.surfaceContainerHighest),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.smMd),
              Center(
                child: Text(
                  '查看訂閱詳情',
                  style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        '啟用中',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
      ),
      backgroundColor: theme.colorScheme.primaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _UsageStat extends StatelessWidget {
  const _UsageStat({required this.label, required this.used, required this.limit});

  final String label;
  final int? used;
  final int? limit;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final canShowProgress = limit != null && used != null;
    final progress = canShowProgress ? (used! / limit!).clamp(0.0, 1.0) : 0.0;

    final Widget valueText = RichText(
      text: TextSpan(
        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        children: [
          TextSpan(text: used?.toString() ?? '—'),
          TextSpan(
            text: ' / ${limit?.toString() ?? '—'}',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        valueText,
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              canShowProgress ? colorScheme.onSurface : colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}
