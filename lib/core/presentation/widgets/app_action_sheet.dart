import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// A single action row inside an [showAppActionSheet] menu.
class AppMenuAction {
  const AppMenuAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// Shows a Clean Luxe modal bottom sheet listing [actions].
///
/// Each action is rendered as a [ListTile]; tapping one dismisses the sheet
/// and invokes its callback. An optional [title] is shown as a header, and an
/// optional [hint] is shown as helper text below the actions.
/// Colors are pulled from [AppTheme].
Future<void> showAppActionSheet(
  final BuildContext context, {
  required final List<AppMenuAction> actions,
  final String? title,
  final String? hint,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (final context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.mdLg),
            ],
            if (hint != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final action in actions)
              ListTile(
                leading: Icon(
                  action.icon,
                  color: action.isDestructive ? colorScheme.error : null,
                ),
                title: Text(
                  action.title,
                  style: action.isDestructive
                      ? TextStyle(color: colorScheme.error)
                      : null,
                ),
                subtitle: action.subtitle != null ? Text(action.subtitle!) : null,
                onTap: () {
                  Navigator.pop(context);
                  action.onTap();
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );
}
