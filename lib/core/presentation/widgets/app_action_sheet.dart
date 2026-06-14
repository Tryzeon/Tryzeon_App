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
/// and invokes its callback. An optional [title] is shown as a header.
/// Colors are pulled from [AppTheme].
Future<void> showAppActionSheet(
  final BuildContext context, {
  required final List<AppMenuAction> actions,
  final String? title,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (final context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.mdLg),
          ],
          for (final action in actions)
            ListTile(
              leading: Icon(
                action.icon,
                color: action.isDestructive ? colorScheme.error : null,
              ),
              title: Text(
                action.title,
                style: action.isDestructive ? TextStyle(color: colorScheme.error) : null,
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
  );
}
