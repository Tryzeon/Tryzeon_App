import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/shop_service.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> _handleTryon() async {
    final product = widget.product;
    // 記錄虛擬試穿點擊次數（不等待結果）
    ShopService.incrementTryonCount(product.id!);

    final personalEntry = PersonalEntry.of(context);
    await personalEntry?.tryOnFromStorage(product.imagePath);
  }

  Future<void> _handlePurchase() async {
    final product = widget.product;

    if (product.purchaseLink.isEmpty) {
      TopNotification.show(
        context,
        message: '此商品尚無購買連結',
        type: NotificationType.info,
      );
      return;
    }

    final Uri url = Uri.parse(product.purchaseLink);
    if (!await canLaunchUrl(url)) {
      if (!mounted) return;

      TopNotification.show(
        context,
        message: '無法開啟購買連結',
        type: NotificationType.error,
      );
      return;
    }

    // 記錄購買連結點擊次數（不等待結果）
    ShopService.incrementPurchaseClickCount(product.id!);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(final BuildContext context) {
    final product = widget.product;
    final imageUrl = Supabase.instance.client.storage
        .from('store')
        .getPublicUrl(product.imagePath);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _handlePurchase,
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
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder:
                                (
                                  final context,
                                  final child,
                                  final loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                    ),
                                  );
                                },
                            errorBuilder:
                                (
                                  final context,
                                  final error,
                                  final stackTrace,
                                ) => Container(
                                  color: colorScheme.surfaceContainer,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                          )
                        : Container(
                            color: colorScheme.surfaceContainer,
                            child: const Icon(Icons.image),
                          ),
                  ),
                  // Try-on button at bottom right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleTryon,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
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
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
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
