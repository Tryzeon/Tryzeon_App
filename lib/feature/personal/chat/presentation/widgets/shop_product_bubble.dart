import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/trigger_product_tryon.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

/// A recommended shop product as its own chat bubble: image, name, price and a
/// try-on button. Tap opens the product detail page.
class ShopProductBubble extends StatelessWidget {
  const ShopProductBubble({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(AppRoutes.personalShopProductPath(product.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(aspectRatio: 1, child: _ShopImage(product: product)),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _ShopInfo(product: product),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopImage extends StatelessWidget {
  const _ShopImage({required this.product});
  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    if (url == null) {
      return Container(
        color: colorScheme.surfaceContainerLow,
        child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: product.imagePaths.isNotEmpty ? product.imagePaths.first : null,
      fit: BoxFit.cover,
      placeholder: (final _, final _) =>
          Container(color: colorScheme.surfaceContainerLow),
      errorWidget: (final _, final _, final _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

class _ShopInfo extends ConsumerWidget {
  const _ShopInfo({required this.product});
  final ShopProduct product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);

    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final hasVideoAccess = capabilitiesAsync.maybeWhen(
      data: (final capabilities) => capabilities.hasVideoAccess,
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Chip(label: Text('推薦商品')),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          product.name,
          style: theme.textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NT\$${product.price.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium,
            ),
            TryOnFab(
              size: 18,
              label: '試穿',
              onTap: () => triggerProductTryOn(
                context,
                ref,
                product,
                hasVideoAccess: hasVideoAccess,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
