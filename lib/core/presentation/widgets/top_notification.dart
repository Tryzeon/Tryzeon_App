import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Failure-only top banner (Direction A — refined card).
/// White surface, soft tinted icon container, generous radius, lifted shadow.
/// Success states stay silent; download-style results use AppSnackBar.
///
/// Stays until the user taps it — errors must not disappear on a timer.
class TopNotification {
  static void show(final BuildContext context, {required final String message}) {
    HapticFeedback.mediumImpact();

    toastification.showCustom(
      context: context,
      alignment: Alignment.topCenter,
      direction: TextDirection.ltr,
      animationDuration: AppDuration.slow,
      animationBuilder: (final context, final animation, final alignment, final child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppCurves.emphasized)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppCurves.emphasized),
            child: child,
          ),
        );
      },
      builder: (final context, final holder) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.dialogAll,
                border: Border.all(color: colorScheme.outline),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppRadius.dialogAll,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.smMd,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.smMd),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.smMd,
                          ),
                          child: Text(
                            message,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => toastification.dismiss(holder),
                        tooltip: '關閉',
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
