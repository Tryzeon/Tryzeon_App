import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '搜尋品牌或商品',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          controller.clear();
                          onSearch('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: onSearch,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSearch(controller.text),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Icon(Icons.search, color: colorScheme.onPrimary, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
