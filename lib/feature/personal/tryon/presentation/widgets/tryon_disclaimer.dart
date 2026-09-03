import 'package:flutter/material.dart';

/// Rendered at full opacity — it sits over an arbitrary user photo, and the
/// bottom gradient alone does not guarantee contrast against a bright one.
class TryonDisclaimer extends StatelessWidget {
  const TryonDisclaimer({super.key});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'AI 生成試穿結果，僅供參考',
      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary),
    );
  }
}
