import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

class ProductStyleSheet extends HookWidget {
  const ProductStyleSheet({super.key, required this.initialSelection});

  final List<ClothingStyle> initialSelection;

  static Future<List<ClothingStyle>?> show({
    required final BuildContext context,
    required final List<ClothingStyle> initialSelection,
  }) {
    return showModalBottomSheet<List<ClothingStyle>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) => ProductStyleSheet(initialSelection: initialSelection),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final selection = useState<Set<ClothingStyle>>(initialSelection.toSet());
    final searchController = useTextEditingController();
    useListenable(searchController);

    void toggle(final ClothingStyle style) {
      final next = {...selection.value};
      if (next.contains(style)) {
        next.remove(style);
      } else {
        next.add(style);
      }
      selection.value = next;
    }

    void done() {
      Navigator.of(context).pop(selection.value.toList());
    }

    final query = searchController.text.trim().toLowerCase();
    final styles = useMemoized(() {
      if (query.isEmpty) return ClothingStyle.values;
      return ClothingStyle.values
          .where(
            (final s) =>
                s.label.toLowerCase().contains(query) ||
                s.value.toLowerCase().contains(query),
          )
          .toList();
    }, [query]);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('選擇風格', style: textTheme.titleMedium),
                TextButton(onPressed: done, child: const Text('完成')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜尋風格...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: styles.isEmpty
                ? Center(
                    child: Text(
                      '沒有符合的風格',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: styles.length,
                    itemBuilder: (final context, final index) {
                      final style = styles[index];
                      final isSelected = selection.value.contains(style);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (final _) => toggle(style),
                        title: Text(style.label),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
