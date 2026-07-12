import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/order_message_builder.dart';
import 'package:tryzeon/feature/personal/shop/presentation/sheets/pre_purchase_sheet.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// True when the product can be bought online or ordered via a store DM channel.
bool productHasPurchaseOptions(final ShopProduct product) =>
    (product.purchaseLink != null && product.purchaseLink!.isNotEmpty) ||
    product.storeInfo.orderContacts.isNotEmpty;

Future<void> launchProductPurchase(
  final BuildContext context,
  final WidgetRef ref,
  final ShopProduct product,
  final FitResult fitResult,
) async {
  if (!productHasPurchaseOptions(product)) return;

  final choice = await PrePurchaseSheet.show(
    context: context,
    product: product,
    fitResult: fitResult,
  );
  if (choice == null || !context.mounted) return;

  final target = _resolveTarget(choice, product, fitResult);

  final incrementClick = ref.read(incrementPurchaseClickCountProvider);

  if (!await canLaunchUrl(target.uri)) {
    if (context.mounted) {
      TopNotification.show(context, message: target.failureMessage);
    }
    return;
  }

  incrementClick.call(productId: product.id, storeId: product.storeInfo.id).ignore();
  await launchUrl(target.uri, mode: LaunchMode.externalApplication);
}

/// Resolves the external target for a purchase [choice]: the URL to open and
/// the message shown if it can't be opened.
({Uri uri, String failureMessage}) _resolveTarget(
  final PurchaseChoice choice,
  final ShopProduct product,
  final FitResult fitResult,
) {
  switch (choice) {
    case OnlineStoreChoice():
      return (uri: Uri.parse(product.purchaseLink!), failureMessage: '無法開啟購買連結');
    case ContactChoice(:final contact):
      final message = OrderMessageBuilder.build(product: product, fitResult: fitResult);
      return (
        uri: _buildOrderContactUri(contact, message),
        failureMessage: '無法開啟 ${contact.type.label} 聊天室',
      );
  }
}

/// Builds the outbound deep link for a store contact channel.
/// LINE prefills the message; FB/IG can only open the chat (paste required).
Uri _buildOrderContactUri(final StoreOrderContact contact, final String message) {
  switch (contact.type) {
    case OrderContactType.line:
      return Uri.parse(
        'https://line.me/R/oaMessage/${contact.value}/?${Uri.encodeComponent(message)}',
      );
    case OrderContactType.facebook:
      return Uri.parse('https://m.me/${contact.value}');
    case OrderContactType.instagram:
      return Uri.parse('https://ig.me/m/${contact.value}');
  }
}
