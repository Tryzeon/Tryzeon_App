import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class PaywallPage extends HookConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final hasPopped = useState(false);

    void safePop() {
      if (!hasPopped.value && context.mounted) {
        hasPopped.value = true;
        context.pop();
      }
    }

    return Scaffold(
      body: SafeArea(
        child: PaywallView(
          onPurchaseCompleted: (final customerInfo, final storeTransaction) {
            AppLogger.info('Purchase completed: ${storeTransaction.productIdentifier}');
            safePop();
          },
          onRestoreCompleted: (final customerInfo) {
            AppLogger.info('Restore completed');
            safePop();
          },
          onPurchaseError: (final error) {
            AppLogger.error('Purchase failed', error.message);
            TopNotification.show(context, message: '購買失敗：${error.message}');
          },
          onRestoreError: (final error) {
            AppLogger.error('Restore failed', error.message);
            TopNotification.show(context, message: '恢復購買失敗：${error.message}');
          },
          onDismiss: () {
            safePop();
          },
        ),
      ),
    );
  }
}
