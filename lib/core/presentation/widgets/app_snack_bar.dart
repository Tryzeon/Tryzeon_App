import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Silent result feedback (e.g. "saved to album"). Floats above the bottom
/// safe area, plus the in-app nav bar on iOS 26+ which the framework's safe
/// area padding doesn't account for. Failures should use `TopNotification`.
class AppSnackBar {
  static void show(
    final BuildContext context, {
    required final String message,
    final String? actionLabel,
    final VoidCallback? onAction,
  }) {
    final liftsItself =
        Scaffold.maybeOf(context)?.hasFloatingActionButton ?? false;

    final navBarOffset = PlatformInfo.isIOS26OrHigher() && !liftsItself
        ? AppSpacing.iosTabBarHeight
        : 0.0;

    final hasAction = actionLabel != null && onAction != null;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: hasAction
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,

        persist: false,
        duration: hasAction
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4),
        margin: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.sm + navBarOffset,
        ),
      ),
    );
  }
}
