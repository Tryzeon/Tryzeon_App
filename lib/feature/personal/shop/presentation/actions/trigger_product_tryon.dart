import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/providers/product_fit_provider.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

/// Shows the try-on mode picker for [product], then starts try-on with the
/// selected mode: increments the product's try-on count and hands off to
/// [tryonCoordinatorProvider].
void triggerProductTryon(
  final BuildContext context,
  final WidgetRef ref,
  final ShopProduct product,
) {
  HapticFeedback.mediumImpact();
  TryonModeSheet.show(
    context: context,
    onModeSelected: (final mode) => _startTryon(ref, product, mode),
  );
}

Future<void> _startTryon(
  final WidgetRef ref,
  final ShopProduct product,
  final TryonMode mode,
) async {
  ref
      .read(incrementTryonCountProvider)
      .call(productId: product.id, storeId: product.storeInfo.id)
      .ignore();

  final sizeId = ref.read(productFitResolverProvider).resolve(product).tryonSizeId;

  await ref
      .read(tryonCoordinatorProvider)
      .tryonFromProduct(product.id, sizeId: sizeId, mode: mode);
}
