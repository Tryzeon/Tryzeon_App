import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/fit_status.dart';
import 'package:tryzeon/feature/personal/shop/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

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

    Future<void> handlePurchase() async {
      if (product.purchaseLink == null || product.purchaseLink!.isEmpty) {
        TopNotification.show(context, message: '此商品尚無購買連結', type: NotificationType.info);
        return;
      }

      final Uri url = Uri.parse(product.purchaseLink!);
      if (!await canLaunchUrl(url)) {
        if (!context.mounted) return;

        TopNotification.show(context, message: '無法開啟購買連結', type: NotificationType.error);
        return;
      }

      // 記錄購買連結點擊次數 (非同步執行，不阻塞 UI)
      ref.read(incrementPurchaseClickCountProvider).call(product.id!).ignore();
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    return GestureDetector(
      onTap: handlePurchase,
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
                    product.storeName!,
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
