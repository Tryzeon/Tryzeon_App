import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ErrorView extends HookConsumerWidget {
  const ErrorView({super.key, this.onRetry, this.isCompact = false, this.message});

  final VoidCallback? onRetry;
  final bool isCompact;
  final String? message;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? AppSpacing.smMd : AppSpacing.mdLg),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: AppOpacity.medium),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isCompact ? AppSpacing.xl : AppSpacing.xxl,
                color: colorScheme.error,
              ),
            ),
            if (!isCompact) const SizedBox(height: AppSpacing.lg),
            Text(
              '很抱歉發生錯誤',
              style: (isCompact ? textTheme.titleSmall : textTheme.titleMedium),
              textAlign: TextAlign.center,
            ),
            if (message != null && !isCompact) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('點我重試'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
