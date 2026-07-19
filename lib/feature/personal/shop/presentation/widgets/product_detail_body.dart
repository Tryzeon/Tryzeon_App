import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/launch_product_purchase.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/trigger_product_tryon.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_image_viewer.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_info_section.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_size_table.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_store_info.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

class ProductDetailBody extends HookConsumerWidget {
  const ProductDetailBody({super.key, required this.productAsync, required this.onRetry});

  final AsyncValue<ShopProduct> productAsync;
  final VoidCallback onRetry;

  /// Skeleton data for loading state
  static final _skeletonProduct = ShopProduct(
    id: 'skeleton_product',
    storeInfo: const ShopStoreInfo(
      id: 'skeleton_store',
      name: 'Loading Store Name',
      channels: StoreChannel.all,
      address: 'Loading Store Address',
    ),
    name: 'Loading Product Name here that is long',
    categoryIds: ['Category 1'],
    price: 8888.0,
    imagePaths: ['skeleton_path'],
    imageUrls: [],
    createdAt: DateTime(2000),
    updatedAt: DateTime(2000),
    material: 'Loading Material Description',
  );

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Priority 1: Show data if available (even during loading or error)
    if (productAsync.hasValue) {
      return Skeletonizer(
        enabled: productAsync.isLoading,
        child: _ProductDetailContent(product: productAsync.requireValue),
      );
    }

    // Priority 2: Show skeleton when loading without data
    if (productAsync.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: _ProductDetailContent(product: _skeletonProduct),
      );
    }

    // Priority 3: Show error when failed without data
    return ErrorView(
      message: productAsync.error.displayMessage(context),
      onRetry: onRetry,
    );
  }
}

class _ProductDetailContent extends HookConsumerWidget {
  const _ProductDetailContent({required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categoryIdToName = categoriesAsync.maybeWhen(
      data: (final categories) => {for (final cat in categories) cat.id: cat.name},
      orElse: () => <String, String>{},
    );

    final userProfile = ref
        .watch(userProfileProvider)
        .maybeWhen(data: (final p) => p, orElse: () => null);
    final fitResult = useMemoized(
      () =>
          FitCalculator.calculate(userProfile: userProfile, productSizes: product.sizes),
      [userProfile, product.sizes],
    );

    final canPurchase = productHasPurchaseOptions(product);

    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final hasVideoAccess = capabilitiesAsync.maybeWhen(
      data: (final capabilities) => capabilities.hasVideoAccess,
      orElse: () => false,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ProductImageViewer(
                imageUrls: product.imageUrls,
                imagePaths: product.imagePaths,
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
                      hasVideoAccess: hasVideoAccess,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mdLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...product.categoryIds.map(
                      (final categoryId) => Chip(
                        label: Text(
                          categoryIdToName[categoryId] ?? categoryId,
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ),
                    if (product.styles != null && product.styles!.isNotEmpty)
                      ...product.styles!.map(
                        (final style) =>
                            Chip(label: Text(style.label, style: textTheme.labelMedium)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.smMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: textTheme.headlineLarge),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '\$${product.price}',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canPurchase)
                      _PurchaseLink(
                        onTap: () =>
                            launchProductPurchase(context, ref, product, fitResult),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.mdLg),
                const Divider(),
                const SizedBox(height: AppSpacing.mdLg),

                // Store Info Section
                ProductStoreInfo(storeInfo: product.storeInfo),
                const SizedBox(height: AppSpacing.xl),

                // Product Info Section (Material, Elasticity, Fit, Thickness)
                if (product.elasticity != null ||
                    product.fit != null ||
                    product.thickness != null ||
                    product.material != null ||
                    (product.seasons != null && product.seasons!.isNotEmpty)) ...[
                  ProductInfoSection(product: product),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Size Info Section
                if (product.sizes != null && product.sizes!.isNotEmpty) ...[
                  ProductSizeTable(sizes: product.sizes!, fitResult: fitResult),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ],
            ),
          ),

          SizedBox(
            height: PlatformInfo.isIOS26OrHigher()
                ? MediaQuery.of(context).padding.bottom + AppSpacing.iosTabBarHeight
                : 0,
          ),
        ],
      ),
    );
  }
}

class _PurchaseLink extends StatelessWidget {
  const _PurchaseLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary, width: AppStroke.regular),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd,
          vertical: AppSpacing.sm,
        ),
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('前往購買'),
          SizedBox(width: AppSpacing.xs),
          Icon(Icons.arrow_outward_rounded, size: 14),
        ],
      ),
    );
  }
}
