import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product_model.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';
import '../../data/shop_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> _handleTryon() async {
    final product = widget.product;
    // 記錄虛擬試穿點擊次數（不等待結果）
    ShopService.incrementTryonCount(product.id!);

    final personalEntry = PersonalEntry.of(context);
    await personalEntry?.virtualTryOnFromStorage(product.imagePath);
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
      if(!mounted) return;
      
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
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = Supabase.instance.client.storage
        .from('store')
        .getPublicUrl(product.imagePath);

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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                          )
                        : Container(
                            color: Colors.grey[300],
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
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    product.storeName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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