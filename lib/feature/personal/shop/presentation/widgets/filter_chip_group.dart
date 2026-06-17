import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// A titled, multi-select group of [FilterChip]s over a fixed option set.
class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final List<T> options;
  final Set<T> selected;
  final String Function(T value) labelOf;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: options.map((final option) {
            return FilterChip(
              label: Text(labelOf(option)),
              selected: selected.contains(option),
              onSelected: (final isOn) {
                final next = {...selected};
                if (isOn) {
                  next.add(option);
                } else {
                  next.remove(option);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
