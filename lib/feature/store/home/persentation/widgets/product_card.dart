import 'package:flutter/material.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import '../dialogs/product_detail_dialog.dart';

class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    super.key,
    required this.product,
    required this.onUpdate,
  });
  final Product product;
  final VoidCallback onUpdate;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (final context) => ProductDetailDialog(product: product),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: FutureBuilder(
                    future: product.loadImage(),
                    builder: (final context, final snapshot) {
                      final result = snapshot.data;
                      if (result != null &&
                          result.isSuccess &&
                          result.file != null) {
                        return Image.file(
                          result.file!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (final context, final error, final stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                        );
                      }
                      if (result != null && !result.isSuccess) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          TopNotification.show(
                            context,
                            message: result.errorMessage ?? '載入圖片失敗',
                            type: NotificationType.error,
                          );
                        });
                        return const Center(
                          child: Icon(Icons.error_outline, color: Colors.grey),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.types.join(', '), // 顯示所有類型，用逗號分隔
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.tryonCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.link, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${product.purchaseClickCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
