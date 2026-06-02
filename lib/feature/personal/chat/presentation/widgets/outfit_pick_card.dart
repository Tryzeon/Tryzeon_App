import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

/// Shared mini card used in chat recommendation slots. Image-only, square,
/// outlined, no elevation — Clean Luxe.
class OutfitPickCard extends StatelessWidget {
  const OutfitPickCard._({required this.child, required this.onTap});

  factory OutfitPickCard.wardrobe({
    required final WardrobeItem item,
    required final BuildContext context,
  }) {
    return OutfitPickCard._(
      onTap: () => context.push(AppRoutes.personalWardrobeItemPath(item.id)),
      child: _WardrobeImage(imagePath: item.imagePath),
    );
  }

  factory OutfitPickCard.shop({
    required final ShopProduct product,
    required final BuildContext context,
  }) {
    return OutfitPickCard._(
      onTap: () => context.push(AppRoutes.personalShopProductPath(product.id)),
      child: _ShopImage(product: product),
    );
  }

  /// Edge length of the square card. Shared so slot rows and skeletons stay
  /// in sync with the rendered card.
  static const double size = 88;

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

class _WardrobeImage extends ConsumerWidget {
  const _WardrobeImage({required this.imagePath});
  final String imagePath;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageFileAsync = ref.watch(wardrobeItemImageProvider(imagePath));
    return imageFileAsync.when(
      data: (final file) => Image.file(file, fit: BoxFit.cover),
      loading: () => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
        ),
      ),
      error: (final _, final _) =>
          Icon(Icons.image_not_supported_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _ShopImage extends StatelessWidget {
  const _ShopImage({required this.product});
  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    final cacheKey = product.imagePaths.isNotEmpty ? product.imagePaths.first : null;

    if (imageUrl == null) {
      return Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      placeholder: (final _, final _) =>
          Container(color: colorScheme.surfaceContainerLow),
      errorWidget: (final _, final _, final _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
