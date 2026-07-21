import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';
import 'package:tryzeon/feature/personal/shop/presentation/state/shop_products_notifier.dart';

import 'product_card.dart';

/// Lazily-built product grid, returned as a single sliver so it can live
/// inside the page's [CustomScrollView] (only visible cells are built).
///
/// Renders four states from [productsAsync]: data (grid + load-more footer),
/// empty, loading (skeleton), and error.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    super.key,
    required this.productsAsync,
    required this.userProfile,
    required this.onRetry,
  });

  final AsyncValue<ShopProductsState> productsAsync;
  final UserProfile? userProfile;
  final VoidCallback onRetry;

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
    childAspectRatio: 0.7,
  );

  /// Skeleton data for the initial loading state.
  static final _skeletonProducts = List<ShopProduct>.generate(
    4,
    (final index) => ShopProduct(
      id: 'skeleton_$index',
      storeInfo: const ShopStoreInfo(
        id: 'skeleton_store',
        name: 'Loading Store',
        channels: StoreChannel.all,
      ),
      name: 'Loading Product Name',
      categoryIds: const ['Category'],
      price: 8888,
      imagePaths: const ['skeleton_path'],
      imageUrls: const [],
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    ),
  );

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Priority 1: show data if available (even during loading or error).
    if (productsAsync.hasValue) {
      final productsState = productsAsync.value!;
      final products = productsState.items;

      if (products.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '目前沒有商品符合搜尋條件',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            sliver: SliverGrid.builder(
              gridDelegate: _gridDelegate,
              itemCount: products.length,
              itemBuilder: (final context, final index) {
                final product = products[index];
                final fitResult = FitCalculator.calculate(
                  userProfile: userProfile,
                  productSizes: product.sizes,
                );
                return ProductCard(product: product, fitResult: fitResult);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _LoadMoreFooter(isLoadingMore: productsState.isLoadingMore),
          ),
        ],
      );
    }

    // Priority 2: skeleton while loading without data.
    if (productsAsync.isLoading) {
      return SliverToBoxAdapter(
        child: Skeletonizer(
          enabled: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _skeletonProducts.length,
              gridDelegate: _gridDelegate,
              itemBuilder: (final context, final index) => ProductCard(
                product: _skeletonProducts[index],
                fitResult: const FitResult(),
              ),
            ),
          ),
        ),
      );
    }

    // Priority 3: error without data.
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ErrorView(
        message: productsAsync.error.displayMessage(context),
        onRetry: onRetry,
      ),
    );
  }
}

/// Footer under the grid: a centered spinner while the next page loads,
/// otherwise a small spacer.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.isLoadingMore});

  final bool isLoadingMore;

  @override
  Widget build(final BuildContext context) {
    if (!isLoadingMore) return const SizedBox(height: AppSpacing.md);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
        ),
      ),
    );
  }
}
