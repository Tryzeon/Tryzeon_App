import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ProductTypeSelector extends HookWidget {
  const ProductTypeSelector({
    super.key,
    required this.allCategories,
    required this.selectedCategories,
  });

  final List<String> allCategories;
  final ValueNotifier<Set<String>> selectedCategories;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedKeysNotifier = useListenable(selectedCategories);
    final selectedKeys = selectedKeysNotifier.value;

    void showSelectionSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final context) => _SelectionSheet(
          allCategories: allCategories,
          selectedKeys: selectedKeys,
          onSelectionChanged: (final keys) {
            selectedCategories.value = keys;
          },
        ),
      );
    }

    return GestureDetector(
      onTap: showSelectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedKeys.isEmpty
                  ? Text(
                      '選擇商品類型',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedKeys.map((final key) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            key,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SelectionSheet extends HookWidget {
  const _SelectionSheet({
    required this.allCategories,
    required this.selectedKeys,
    required this.onSelectionChanged,
  });

  final List<String> allCategories;
  final Set<String> selectedKeys;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final searchController = useTextEditingController();
    useListenable(searchController);

    // Local state for the sheet
    final currentSelection = useState<Set<String>>({...selectedKeys});

    void toggleSelection(final String key) {
      final newSet = {...currentSelection.value};
      if (newSet.contains(key)) {
        newSet.remove(key);
      } else {
        newSet.add(key);
      }
      currentSelection.value = newSet;
    }

    void saveAndClose() {
      onSelectionChanged(currentSelection.value);
      Navigator.pop(context);
    }

    final filteredCategories = useMemoized(() {
      final query = searchController.text.trim().toLowerCase();
      if (query.isEmpty) return allCategories;
      return allCategories
          .where((final category) => category.toLowerCase().contains(query))
          .toList();
    }, [allCategories, searchController.text]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '選擇類型',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: saveAndClose,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchController,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '搜尋類型...',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Flexible(
              child: filteredCategories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          '沒有找到符合的類型',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredCategories.length,
                      itemBuilder: (final context, final index) {
                        final key = filteredCategories[index];
                        final isSelected = currentSelection.value.contains(key);

                        return InkWell(
                          onTap: () => toggleSelection(key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    key,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                    size: 24,
                                  )
                                else
                                  Icon(
                                    Icons.circle_outlined,
                                    color: colorScheme.outline,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Keyboard spacing
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
