import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/trigger_product_tryon.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ProductCard extends HookConsumerWidget {
  const ProductCard({super.key, required this.product, this.fitResult});

  final ShopProduct product;
  final FitResult? fitResult;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasLoggedView = useState(false);

    void onVisibilityChanged(final VisibilityInfo info) {
      if (product.id.startsWith('skeleton_')) return;

      if (info.visibleFraction > AppConstants.productVisibilityThreshold &&
          !hasLoggedView.value) {
        hasLoggedView.value = true;
        ref
            .read(incrementViewCountProvider)
            .call(productId: product.id, storeId: product.storeInfo.id)
            .ignore();
      }
    }

    final recommendedSize = fitResult?.displayState == FitDisplayState.match
        ? fitResult?.recommendedSize
        : null;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.personalShopProductPath(product.id), extra: product);
      },
      child: VisibilityDetector(
        key: Key('product-card-${product.id}'),
        onVisibilityChanged: onVisibilityChanged,
        child: Card(
          color: colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: colorScheme.surfaceContainerLow,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: product.imageUrls.isEmpty
                            ? const _ImagePlaceholder()
                            : PageView.builder(
                                itemCount: product.imageUrls.length,
                                itemBuilder: (final context, final index) {
                                  return CachedNetworkImage(
                                    imageUrl: product.imageUrls[index],
                                    cacheKey: product.imagePaths[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholder: (final context, final url) =>
                                        Container(color: colorScheme.surfaceContainerLow),
                                    errorWidget:
                                        (final context, final url, final error) =>
                                            const Center(
                                              child: Icon(Icons.broken_image_outlined),
                                            ),
                                  );
                                },
                              ),
                      ),
                      Positioned(
                        bottom: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Skeleton.ignore(
                          child: TryonFab(
                            onTap: () => triggerProductTryon(
                              context,
                              ref,
                              product,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.smMd),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.storeInfo.name.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            product.name,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '\$${product.price}',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (recommendedSize != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Skeleton.ignore(
                            child: _SizeChip(sizeName: recommendedSize),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.sizeName});

  final String sizeName;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.fitMatchContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 10, color: AppColors.onFitMatchContainer),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            sizeName,
            style: textTheme.labelMedium?.copyWith(color: AppColors.onFitMatchContainer),
          ),
        ],
      ),
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
