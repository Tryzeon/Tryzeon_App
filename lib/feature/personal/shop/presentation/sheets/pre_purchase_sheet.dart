import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/order_message_builder.dart';
import 'package:tryzeon/feature/personal/shop/presentation/mappers/fit_result_ui_mapper.dart';

/// The action the user picked in [PrePurchaseSheet]; null when cancelled.
sealed class PurchaseChoice {
  const PurchaseChoice();
}

class OnlineStoreChoice extends PurchaseChoice {
  const OnlineStoreChoice();
}

class ContactChoice extends PurchaseChoice {
  const ContactChoice(this.contact);
  final StoreOrderContact contact;
}

class PrePurchaseSheet extends StatelessWidget {
  const PrePurchaseSheet({super.key, required this.product, required this.fitResult});

  final ShopProduct product;
  final FitResult fitResult;

  static Future<PurchaseChoice?> show({
    required final BuildContext context,
    required final ShopProduct product,
    required final FitResult fitResult,
  }) {
    return showModalBottomSheet<PurchaseChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) => PrePurchaseSheet(product: product, fitResult: fitResult),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageUrl: product.imageUrls.firstOrNull),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.storeInfo.name.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        product.name,
                        style: textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$${product.price}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (fitResult.displayState != FitDisplayState.unknown) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              _FitInfoRow(fitResult: fitResult),
              const Divider(),
              const SizedBox(height: AppSpacing.smMd),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
            ],

            _CopyMessageButton(
              message: OrderMessageBuilder.build(product: product, fitResult: fitResult),
            ),
            const SizedBox(height: AppSpacing.smMd),

            if (product.purchaseLink != null && product.purchaseLink!.isNotEmpty) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(const OnlineStoreChoice()),
                child: const Text('開啟購買連結'),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            for (final contact in product.storeInfo.orderContacts) ...[
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(ContactChoice(contact)),
                child: Text(_contactLabel(contact.type)),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AppRadius.inputAll,
      child: SizedBox(
        width: 72,
        height: 90,
        child: imageUrl == null
            ? Container(
                color: colorScheme.surfaceContainerLow,
                child: Icon(
                  Icons.image_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (final context, final url) =>
                    Container(color: colorScheme.surfaceContainerLow),
                errorWidget: (final context, final url, final error) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
      ),
    );
  }
}

class _FitInfoRow extends StatelessWidget {
  const _FitInfoRow({required this.fitResult});

  final FitResult fitResult;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final iconColor = switch (fitResult.displayState) {
      FitDisplayState.match => AppColors.fitMatch,
      FitDisplayState.caveats => AppColors.fitCaveat,
      FitDisplayState.outOfRange => AppColors.fitOutOfRange,
      FitDisplayState.noUserData ||
      FitDisplayState.unknown => colorScheme.onSurfaceVariant,
    };

    final onTap = fitResult.displayState == FitDisplayState.noUserData
        ? () {
            // Capture the router before popping; the sheet's context is
            // disposed by the time `push` would run.
            final router = GoRouter.of(context);
            Navigator.of(context, rootNavigator: true).pop(false);
            router.push(AppRoutes.personalSettingsBodyMeasurements);
          }
        : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(fitResult.iconData, size: 16, color: iconColor),
      title: Text(
        fitResult.headline,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        fitResult.subline,
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
    );
  }
}

String _contactLabel(final OrderContactType type) => switch (type) {
  OrderContactType.line => '用 LINE 詢問下單',
  OrderContactType.facebook => 'FB 私訊下單',
  OrderContactType.instagram => 'IG 私訊下單',
};

class _CopyMessageButton extends StatefulWidget {
  const _CopyMessageButton({required this.message});

  final String message;

  @override
  State<_CopyMessageButton> createState() => _CopyMessageButtonState();
}

class _CopyMessageButtonState extends State<_CopyMessageButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(final BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _copy,
      icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
      label: Text(_copied ? '已複製商品資訊' : '複製商品資訊與尺寸'),
    );
  }
}
