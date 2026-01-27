import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';

import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/fit_status.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/product_detail_page.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';

class ProductCard extends HookConsumerWidget {
  const ProductCard({super.key, required this.product, this.fitStatus});

  final ShopProduct product;
  final FitStatus? fitStatus;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color getFitColor(final FitStatus status) {
      switch (status) {
        case FitStatus.perfect:
          return Colors.green;
        case FitStatus.good:
          return Colors.amber;
        case FitStatus.poor:
          return Colors.red;
        case FitStatus.unknown:
          return colorScheme.primary;
      }
    }

    Future<void> handleTryon() async {
      // 記錄虛擬試穿點擊次數 (非同步執行，不阻塞 UI)
      ref.read(incrementTryonCountProvider).call(product.id!).ignore();

      // 如果契合度為紅色，彈出確認視窗
      if (fitStatus == FitStatus.poor) {
        final confirmed = await ConfirmationDialog.show(
          context: context,
          title: '尺寸不合',
          content: '這件衣服不合身，是否還要繼續試穿？',
          confirmText: '繼續試穿',
          cancelText: '取消',
        );

        if (confirmed != true) {
          return;
        }
      }

      if (!context.mounted) return;

      final personalEntry = PersonalEntry.of(context);
      await personalEntry?.tryOnFromStorage(product.imagePath);
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (final context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      cacheKey: product.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (final context, final url) => Center(
                        child: CircularProgressIndicator(color: colorScheme.primary),
                      ),
                      errorWidget: (final context, final url, final error) => Container(
                        color: colorScheme.surfaceContainer,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  // Try-on button with fit color at bottom right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: handleTryon,
                        borderRadius: BorderRadius.circular(20),
                        child: Builder(
                          builder: (final context) {
                            final buttonColor = fitStatus == null
                                ? colorScheme.primary
                                : getFitColor(fitStatus!);

                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: buttonColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: colorScheme.onPrimary,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                  Text(
                    product.storeInfo.name ?? '',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
