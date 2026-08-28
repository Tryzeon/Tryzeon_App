import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/actions/toggle_product_status.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_actions_sheet.dart';

class StoreProductCard extends HookConsumerWidget {
  const StoreProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categoryName = categoriesAsync.maybeWhen(
      data: (final categories) =>
          categories.where((final c) => c.id == product.categoryId).firstOrNull?.name,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () => context.push(AppRoutes.dashboardProductDetailPath(product.id)),
      child: Card(
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainerLow,
                child: product.imageUrls.isEmpty
                    ? const _ImagePlaceholder()
                    : CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        cacheKey: product.imagePaths.isNotEmpty
                            ? product.imagePaths.first
                            : null,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (final context, final url) =>
                            Container(color: colorScheme.surfaceContainerLow),
                        errorWidget: (final context, final url, final error) =>
                            const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.smMd,
                AppSpacing.smMd,
                AppSpacing.smMd,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryName != null) ...[
                    Text(
                      categoryName,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    product.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '\$${product.price.toStringAsFixed(0)}',
                    style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.smMd),
              child: Row(
                children: [
                  Expanded(child: _AnalyticsRow(productId: product.id)),
                  _ProductCardMenuButton(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCardMenuButton extends StatelessWidget {
  const _ProductCardMenuButton({required this.product});

  final Product product;

  @override
  Widget build(final BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_horiz, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      tooltip: '更多操作',
      onPressed: () async {
        final confirmed = await ProductActionsSheet.show(context, product);
        if (confirmed != true || !context.mounted) return;

        await toggleProductStatus(context, product);
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _AnalyticsRow extends ConsumerWidget {
  const _AnalyticsRow({required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analytics = ref.watch(
      productAnalyticsSummariesProvider.select(
        (final async) =>
            async.value?.where((final s) => s.productId == productId).firstOrNull,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnalyticsBadge(
          icon: Icons.visibility_outlined,
          count: analytics?.viewCount ?? 0,
        ),
        const SizedBox(width: AppSpacing.smMd),
        _AnalyticsBadge(
          icon: Icons.checkroom_outlined,
          count: analytics?.tryonCount ?? 0,
        ),
        const SizedBox(width: AppSpacing.smMd),
        _AnalyticsBadge(
          icon: Icons.north_east_rounded,
          count: analytics?.purchaseClickCount ?? 0,
        ),
      ],
    );
  }
}

class _AnalyticsBadge extends StatelessWidget {
  const _AnalyticsBadge({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          count.toString(),
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
