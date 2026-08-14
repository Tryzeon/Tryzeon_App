import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class RevenueCatUiUtils {
  /// Always presents the Paywall Page regardless of current entitlement.
  static void presentPaywall(final BuildContext context) {
    context.push(AppRoutes.personalPaywall);
  }

  /// Presents the RevenueCat Customer Center for the user to manage their
  /// subscription.
  ///
  /// Nothing is refreshed on the way out: RevenueCat pushes the new CustomerInfo
  /// to `appSubscriptionEntitlementProvider`'s listener. A plan change made on
  /// the store's own page can lag by up to RevenueCat's cache TTL — accepted, in
  /// exchange for having no cache handling here at all.
  static Future<void> presentCustomerCenter(final BuildContext context) async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e, stackTrace) {
      AppLogger.error('Customer Center failed to open', e, stackTrace);
      if (context.mounted) {
        TopNotification.show(context, message: '無法開啟訂閱管理中心');
      }
    }
  }
}
