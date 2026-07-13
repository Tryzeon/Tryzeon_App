import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';

class RevenueCatUiUtils {
  /// Always presents the Paywall Page regardless of current entitlement.
  static void presentPaywall(final BuildContext context) {
    context.push(AppRoutes.personalPaywall);
  }

  /// Presents the RevenueCat Customer Center for the user to manage their subscription.
  static Future<void> presentCustomerCenter(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    try {
      await RevenueCatUI.presentCustomerCenter();

      // After returning from Customer Center, refresh the entitlement status
      // in case the user upgraded, downgraded, or canceled.
      ref.invalidate(appSubscriptionEntitlementProvider);
      ref.invalidate(subscriptionCapabilitiesProvider);
    } catch (e, stackTrace) {
      AppLogger.error('Customer Center failed to open', e, stackTrace);
      if (context.mounted) {
        TopNotification.show(context, message: '無法開啟訂閱管理中心');
      }
    }
  }
}
