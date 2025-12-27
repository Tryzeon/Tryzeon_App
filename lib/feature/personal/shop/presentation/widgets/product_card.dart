import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/personal/presentation/pages/settings/data/profile_service.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/shop_service.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, this.userProfile});

  final Product product;
  final UserProfile? userProfile;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  void initState() {
    super.initState();
  }

  // 計算契合度等級：返回 'green', 'yellow', 'red' 或 null
  String? _calculateFitLevel(final UserProfile? userProfile) {
    if (userProfile == null || widget.product.sizes == null) {
      return null; // 無法計算
    }

    double? bestDiff;
    // 對每個商品尺寸進行比對
    for (final size in widget.product.sizes!) {
      double totalDiff = 0;
      int comparisonCount = 0;

      for (final type in MeasurementType.values) {
        final userValue = userProfile.measurements[type];
        final sizeValue = size.measurements[type];

        if (userValue != null && sizeValue != null) {
          totalDiff += (userValue - sizeValue).abs();
          comparisonCount++;
        }
      }

      // 如果有比對到資料，記錄最佳差值
      if (comparisonCount > 0) {
        if (bestDiff == null || totalDiff < bestDiff) {
          bestDiff = totalDiff;
        }
      }
    }

    // 根據最佳差值返回等級
    if (bestDiff == null) {
      return null; // 沒有可比對的資料
    } else if (bestDiff <= 5) {
      return 'green';
    } else if (bestDiff <= 10) {
      return 'yellow';
    } else {
      return 'red';
    }
  }

  Color _getFitColor(final String level) {
    switch (level) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleTryon() async {
    final product = widget.product;
    // 記錄虛擬試穿點擊次數 (非同步執行，不阻塞 UI)
    ShopService.incrementTryonCount(product.id!).ignore();

    final personalEntry = PersonalEntry.of(context);
    await personalEntry?.tryOnFromStorage(product.imagePath);
  }

  Future<void> _handlePurchase() async {
    final product = widget.product;

    if (product.purchaseLink == null || product.purchaseLink!.isEmpty) {
      TopNotification.show(context, message: '此商品尚無購買連結', type: NotificationType.info);
      return;
    }

    final Uri url = Uri.parse(product.purchaseLink!);
    if (!await canLaunchUrl(url)) {
      if (!mounted) return;

      TopNotification.show(context, message: '無法開啟購買連結', type: NotificationType.error);
      return;
    }

    // 記錄購買連結點擊次數 (非同步執行，不阻塞 UI)
    ShopService.incrementPurchaseClickCount(product.id!).ignore();
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(final BuildContext context) {
    final product = widget.product;
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
                        onTap: _handleTryon,
                        borderRadius: BorderRadius.circular(20),
                        child: Builder(
                          builder: (final context) {
                            final fitLevel = _calculateFitLevel(widget.userProfile);
                            final buttonColor = fitLevel == null
                                ? colorScheme.primary
                                : _getFitColor(fitLevel);

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
