import 'package:flutter/material.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:typed_result/typed_result.dart';

import '../pages/product_detail_page.dart';

class StoreProductCard extends StatelessWidget {
  const StoreProductCard({super.key, required this.product, required this.onUpdate});
  final Product product;
  final VoidCallback onUpdate;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (final context) => ProductDetailPage(product: product),
          ),
        );
        if (result == true) {
          onUpdate();
        }
      },
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: FutureBuilder(
                    future: product.loadImage(),
                    builder: (final context, final snapshot) {
                      final result = snapshot.data;
                      if (result != null && result.isSuccess && result.get() != null) {
                        return Image.file(
                          result.get()!,
                          fit: BoxFit.cover,
                          errorBuilder: (final context, final error, final stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        );
                      }
                      if (result != null && !result.isSuccess) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          TopNotification.show(
                            context,
                            message: result.getError()!,
                            type: NotificationType.error,
                          );
                        });
                        return Center(
                          child: Icon(Icons.error_outline, color: colorScheme.error),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
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
                    product.types.join(', '), // 顯示所有類型，用逗號分隔
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text('${product.tryonCount}', style: textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.link,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text('${product.purchaseClickCount}', style: textTheme.bodySmall),
                    ],
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
