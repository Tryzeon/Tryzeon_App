import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SortOptionsDialog {
  SortOptionsDialog({
    required this.context,
    required this.sortBy,
    required this.ascending,
    required this.onSortChange,
    required this.onAscendingChange,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (final BuildContext context) {
        return _SortOptionsDialogContent(
          sortBy: sortBy,
          ascending: ascending,
          onSortChange: onSortChange,
          onAscendingChange: onAscendingChange,
        );
      },
    );
  }
  final BuildContext context;
  final String sortBy;
  final bool ascending;
  final Function(String) onSortChange;
  final Function(bool) onAscendingChange;
}

class _SortOptionsDialogContent extends HookConsumerWidget {
  const _SortOptionsDialogContent({
    required this.sortBy,
    required this.ascending,
    required this.onSortChange,
    required this.onAscendingChange,
  });
  final String sortBy;
  final bool ascending;
  final Function(String) onSortChange;
  final Function(bool) onAscendingChange;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final sortByState = useState(sortBy);
    final ascendingState = useState(ascending);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleSortChange(final String newValue) {
      sortByState.value = newValue;
      onSortChange(newValue);
    }

    void handleAscendingChange(final bool value) {
      ascendingState.value = value;
      onAscendingChange(value);
    }

    Widget buildHeader() {
      return Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sort_rounded, color: colorScheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Text('排序方式', style: textTheme.titleLarge),
        ],
      );
    }

    Widget buildSortOptions() {
      final options = [
        {'label': '名稱', 'value': 'name'},
        {'label': '價格', 'value': 'price'},
        {'label': '建立時間', 'value': 'created_at'},
        {'label': '更新時間', 'value': 'updated_at'},
        {'label': '試穿次數', 'value': 'tryon_count'},
        {'label': '購買點擊次數', 'value': 'purchase_click_count'},
      ];

      return RadioGroup<String>(
        groupValue: sortByState.value,
        onChanged: (final val) {
          if (val != null) {
            handleSortChange(val);
          }
        },
        child: Column(
          children: options.map((final option) {
            final label = option['label']!;
            final value = option['value']!;
            final isSelected = sortByState.value == value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: InkWell(
                onTap: () => handleSortChange(value),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  leading: Radio<String>(
                    value: value,
                    fillColor: WidgetStateProperty.resolveWith((final states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primary;
                      }
                      return null;
                    }),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget buildAscendingSwitch() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          title: Text(
            '排序轉換',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
          ),
          value: ascendingState.value,
          activeTrackColor: colorScheme.primary,
          onChanged: handleAscendingChange,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            const SizedBox(height: 24),
            buildSortOptions(),
            const SizedBox(height: 16),
            buildAscendingSwitch(),
          ],
        ),
      ),
    );
  }
}
