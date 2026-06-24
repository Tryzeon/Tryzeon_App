import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/router/app_routes.dart';

class UpgradeDialog {
  static Future<void> show(
    final BuildContext context, {
    final String? title,
    final String? content,
  }) async {
    final result = await showAppOkCancelDialog(
      context: context,
      title: title ?? '已達使用上限',
      message: content ?? '您的使用次數已達上限\n升級至更高方案以獲得更多額度！',
      okLabel: '前往訂閱',
      cancelLabel: '取消',
    );
    if (result != OkCancelResult.ok) return;
    if (!context.mounted) return;
    context.push(AppRoutes.personalSubscription);
  }
}
