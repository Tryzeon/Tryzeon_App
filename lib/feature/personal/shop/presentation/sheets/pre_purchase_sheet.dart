import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';
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

    final hasOnlineLink =
        product.purchaseLink != null && product.purchaseLink!.isNotEmpty;
    final contacts = product.storeInfo.orderContacts;

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

            if (hasOnlineLink) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(const OnlineStoreChoice()),
                child: const Text('開啟購買連結'),
              ),
              if (contacts.isNotEmpty) const SizedBox(height: AppSpacing.md),
            ],

            if (contacts.isNotEmpty)
              _ContactChannels(
                contacts: contacts,
                message: OrderMessageBuilder.build(
                  product: product,
                  fitResult: fitResult,
                ),
              ),

            const SizedBox(height: AppSpacing.sm),
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

class _ContactChannels extends StatelessWidget {
  const _ContactChannels({required this.contacts, required this.message});

  final List<StoreOrderContact> contacts;
  final String message;

  static const double _stepIndent = _StepBadge.size + AppSpacing.smMd;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '私訊店家下單',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _StepRow(
          number: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text('複製商品與尺寸資訊', style: textTheme.bodyMedium)),
              const SizedBox(width: AppSpacing.smMd),
              _SquareCopyButton(message: message),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),

        _StepRow(number: 2, child: Text('開啟社群軟體，貼上即可向店家下單', style: textTheme.bodyMedium)),
        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: const EdgeInsets.only(left: _stepIndent),
          child: Wrap(
            spacing: AppSpacing.smMd,
            children: [for (final contact in contacts) _ChannelButton(contact: contact)],
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.child});

  final int number;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StepBadge(number),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(child: child),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge(this.number);

  static const double size = 22;

  final int number;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
      child: Text(
        '$number',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SquareCopyButton extends StatefulWidget {
  const _SquareCopyButton({required this.message});

  final String message;

  @override
  State<_SquareCopyButton> createState() => _SquareCopyButtonState();
}

class _SquareCopyButtonState extends State<_SquareCopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message));
    if (!mounted) return;
    await HapticFeedback.selectionClick();
    setState(() => _copied = true);
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: _copied ? '已複製商品資訊' : '複製商品資訊',
      child: InkWell(
        onTap: _copy,
        borderRadius: AppRadius.inputAll,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: AppRadius.inputAll,
            border: Border.all(color: colorScheme.outline),
          ),
          child: AnimatedSwitcher(
            duration: AppDuration.quick,
            child: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              key: ValueKey(_copied),
              size: 20,
              color: _copied ? AppColors.fitMatch : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({required this.contact});

  final StoreOrderContact contact;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '用 ${contact.type.label} 私訊下單',
      child: InkWell(
        onTap: () => Navigator.of(context).pop(ContactChoice(contact)),
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Icon(
            _channelIcon(contact.type),
            size: 24,
            color: _channelColor(contact.type),
          ),
        ),
      ),
    );
  }
}

IconData _channelIcon(final OrderContactType type) => switch (type) {
  OrderContactType.line => SimpleIcons.line,
  OrderContactType.facebook => SimpleIcons.facebook,
  OrderContactType.instagram => SimpleIcons.instagram,
};

Color _channelColor(final OrderContactType type) => switch (type) {
  OrderContactType.line => SimpleIconColors.line,
  OrderContactType.facebook => SimpleIconColors.facebook,
  OrderContactType.instagram => SimpleIconColors.instagram,
};
