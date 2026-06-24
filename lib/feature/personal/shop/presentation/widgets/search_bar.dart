import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tryzeon/core/theme/app_theme.dart';

class ShopSearchBar extends HookConsumerWidget {
  const ShopSearchBar({super.key, required this.onSearch});
  final Future<void> Function(String query) onSearch;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final controller = useTextEditingController();
    useListenable(controller);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: '搜尋品牌或商品',
              prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                      onPressed: () {
                        controller.clear();
                        onSearch('');
                      },
                    ),
            ),
            onSubmitted: onSearch,
          ),
        ),
        const SizedBox(width: AppSpacing.smMd),
        IconButton.filled(
          onPressed: () {
            FocusScope.of(context).unfocus();
            onSearch(controller.text);
          },
          icon: Icon(Icons.search, size: 20, color: colorScheme.onPrimaryContainer),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            padding: const EdgeInsets.all(AppSpacing.smMd),
          ),
        ),
      ],
    );
  }
}
