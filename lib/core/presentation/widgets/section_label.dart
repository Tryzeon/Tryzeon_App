import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Heading above a group of `NavRow`s in a settings-style list.
///
/// [color] overrides the default `onSurfaceVariant` — pass `colorScheme.error`
/// to mark a danger section.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final resolved = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: resolved)),
      ),
    );
  }
}
