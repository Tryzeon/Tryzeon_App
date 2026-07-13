import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

/// Editorial-style gender filter: flat text labels with an animated Terracotta
/// underline on the active one. No boxes, single accent — per the Clean Luxe
/// design language.
class ShopGenderFilter extends StatelessWidget {
  const ShopGenderFilter({super.key, required this.selected, required this.onChanged});

  final ProductGender? selected;
  final ValueChanged<ProductGender?> onChanged;

  static const List<(ProductGender?, String)> _options = [
    (ProductGender.female, '女裝'),
    (ProductGender.male, '男裝'),
  ];

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        for (final (value, label) in _options)
          _GenderTab(
            label: label,
            isSelected: value == selected,
            onTap: () {
              if (value == selected) return;
              HapticFeedback.selectionClick();
              onChanged(value);
            },
          ),
      ],
    );
  }
}

class _GenderTab extends StatelessWidget {
  const _GenderTab({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
              child: Text(label),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 2,
              width: isSelected ? 18 : 0,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
