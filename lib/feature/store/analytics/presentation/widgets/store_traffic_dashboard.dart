import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class StoreTrafficDashboard extends HookConsumerWidget {
  const StoreTrafficDashboard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analyticsAsync = ref.watch(productAnalyticsSummariesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    int totalView = 0;
    int totalTryOn = 0;
    int totalPurchaseClicks = 0;
    bool hasError = false;

    if (analyticsAsync.hasValue && analyticsAsync.value != null) {
      for (final s in analyticsAsync.value!) {
        totalView += s.viewCount;
        totalTryOn += s.tryonCount;
        totalPurchaseClicks += s.purchaseClickCount;
      }
    } else if (analyticsAsync.hasError) {
      hasError = true;
    }

    final isLoading = analyticsAsync.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outline),
          bottom: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          _TrafficStatTile(
            label: '瀏覽',
            value: totalView,
            isLoading: isLoading,
            hasError: hasError,
            isHero: true,
          ),
          _TrafficStatTile(
            label: '試穿',
            value: totalTryOn,
            isLoading: isLoading,
            hasError: hasError,
          ),
          _TrafficStatTile(
            label: '購買點擊',
            value: totalPurchaseClicks,
            isLoading: isLoading,
            hasError: hasError,
          ),
        ],
      ),
    );
  }
}

class _TrafficStatTile extends StatelessWidget {
  const _TrafficStatTile({
    required this.label,
    required this.value,
    required this.isLoading,
    required this.hasError,
    this.isHero = false,
  });

  final String label;
  final int value;
  final bool isLoading;
  final bool hasError;
  final bool isHero;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final valueColor = hasError
        ? colorScheme.onSurfaceVariant
        : (isHero ? colorScheme.primary : colorScheme.onSurface);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeletonizer(
            enabled: isLoading,
            child: Text(
              (isLoading || hasError) ? '--' : value.toString(),
              style: textTheme.headlineLarge?.copyWith(color: valueColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
