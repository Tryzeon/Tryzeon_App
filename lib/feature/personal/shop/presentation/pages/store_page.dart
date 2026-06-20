import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_grid.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class StorePage extends HookConsumerWidget {
  const StorePage({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final storeInfoAsync = ref.watch(storeInfoProvider(storeId));

    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleOpenMap(final String address) async {
      final uri = Uri.parse(
        '${AppConstants.googleMapsQueryUrl}${Uri.encodeComponent(address)}',
      );
      if (!await canLaunchUrl(uri)) {
        if (!context.mounted) return;
        TopNotification.show(context, message: '無法開啟地圖');
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

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
        title: storeInfoAsync.hasValue
            ? Text(storeInfoAsync.value!.name, style: textTheme.titleMedium)
            : const Text('店家'),
        actions: [
          if (storeInfoAsync.hasValue)
            IconButton(
              onPressed: () {
                final store = storeInfoAsync.value!;
                share_plus.SharePlus.instance.share(
                  share_plus.ShareParams(
                    text:
                        '${AppConstants.webBaseUrl}/store/${store.slug ?? store.id}',
                  ),
                );
              },
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                    ? Icons.ios_share
                    : Icons.share,
              ),
            ),
        ],
      ),
      body: storeInfoAsync.when(
        data: (final storeInfo) {
          final filter = ShopFilter(storeId: storeInfo.id);
          final productsAsync = ref.watch(shopProductsProvider(filter));
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(storeInfoProvider(storeId).future),
                refreshShopProducts(ref, filter),
              ]);
            },
            color: colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Store Profile Section
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: storeInfo.logoUrl != null
                              ? CachedNetworkImageProvider(storeInfo.logoUrl!)
                              : null,
                          child: storeInfo.logoUrl == null
                              ? Icon(
                                  Icons.store,
                                  size: 28,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeInfo.name,
                                style: textTheme.displaySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (storeInfo.channels.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: StoreChannel.values
                                      .where(storeInfo.channels.contains)
                                      .map(
                                        (final channel) => Chip(
                                          label: Text(channel.label),
                                          labelStyle: textTheme.labelMedium,
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              if (storeInfo.address != null &&
                                  storeInfo.address!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                InkWell(
                                  onTap: () => handleOpenMap(storeInfo.address!),
                                  borderRadius: AppRadius.buttonAll,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs,
                                      horizontal: AppSpacing.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            storeInfo.address!,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Icon(
                                          Icons.north_east,
                                          size: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.ideographic,
                      children: [
                        Text('所有商品', style: textTheme.titleLarge),
                        const SizedBox(width: AppSpacing.sm),
                        if (productsAsync.hasValue)
                          Text(
                            '${productsAsync.value!.length} 件商品',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Products Section
                  ProductGrid(
                    productsAsync: productsAsync,
                    userProfile: userProfile,
                    onRetry: () => ref.invalidate(shopProductsProvider(filter)),
                  ),
                  SizedBox(
                    height: PlatformInfo.isIOS26OrHigher()
                        ? MediaQuery.of(context).padding.bottom +
                              AppSpacing.iosTabBarHeight
                        : 0,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final error, final stack) => ErrorView(
          message: error.displayMessage(context),
          onRetry: () => ref.refresh(storeInfoProvider(storeId)),
        ),
      ),
    );
  }
}
