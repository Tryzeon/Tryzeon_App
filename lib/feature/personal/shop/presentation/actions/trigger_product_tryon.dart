import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/main/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

/// Shows the try-on mode picker for [product], then starts try-on with the
/// selected mode: increments the product's try-on count and hands off to
/// [tryOnCoordinatorProvider].
void triggerProductTryOn(
  final BuildContext context,
  final WidgetRef ref,
  final ShopProduct product, {
  required final bool hasVideoAccess,
}) {
  HapticFeedback.mediumImpact();
  TryOnModeSheet.show(
    context: context,
    hasVideoAccess: hasVideoAccess,
    onModeSelected: (final mode) => _startTryOn(ref, product, mode),
  );
}

Future<void> _startTryOn(
  final WidgetRef ref,
  final ShopProduct product,
  final TryOnMode mode,
) async {
  ref
      .read(incrementTryonCountProvider)
      .call(productId: product.id, storeId: product.storeInfo.id)
      .ignore();

  await ref
      .read(tryOnCoordinatorProvider)
      .tryOnFromStorage(product.imagePaths, mode: mode);
}
