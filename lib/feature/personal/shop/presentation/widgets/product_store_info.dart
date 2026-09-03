import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

class ProductStoreInfo extends StatelessWidget {
  const ProductStoreInfo({required this.storeInfo, super.key});

  final ShopStoreInfo storeInfo;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('店家資訊', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.smMd),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push(AppRoutes.personalShopStorePath(storeInfo.id));
            },
            borderRadius: AppRadius.cardAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: storeInfo.logoUrl != null
                        ? CachedNetworkImageProvider(storeInfo.logoUrl!)
                        : null,
                    child: storeInfo.logoUrl == null
                        ? Icon(Icons.store, color: colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeInfo.name, style: textTheme.titleSmall),
                        if (storeInfo.address != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(storeInfo.address!, style: textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colorScheme.outlineVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
