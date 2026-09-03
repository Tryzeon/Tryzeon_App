import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/share_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_detail_body.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.productId, this.initialProduct});

  final String productId;
  final ShopProduct? initialProduct;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final initial = initialProduct;
    // initialProduct is a final constructor field and therefore constant for a
    // given widget instance, so this conditional watch is stable across
    // rebuilds.
    final productAsync = initial != null
        ? AsyncValue.data(initial)
        : ref.watch(shopProductByIdProvider(productId));
    final product = productAsync.hasValue ? productAsync.value : null;
    final canShare = product != null;

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.personalHome);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: product != null ? Text(product.name, style: textTheme.titleMedium) : null,
        actions: [
          if (canShare)
            IconButton(
              onPressed: () => shareProduct(product),
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                    ? Icons.ios_share
                    : Icons.share,
              ),
            ),
        ],
      ),
      body: ProductDetailBody(
        productAsync: productAsync,
        onRetry: () => ref.refresh(shopProductByIdProvider(productId).future),
      ),
    );
  }
}
