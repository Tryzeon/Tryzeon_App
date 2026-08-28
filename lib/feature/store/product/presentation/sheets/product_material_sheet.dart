import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

/// `null` from sheet = dismissed (preserve existing); `(value: x)` = confirmed
/// (write `x`, which may itself be null when user explicitly cleared).
typedef ProductMaterialResult = ({String? value});

class ProductMaterialSheet extends HookWidget {
  const ProductMaterialSheet({super.key, required this.initialValue});

  final String? initialValue;

  static Future<ProductMaterialResult?> show({
    required final BuildContext context,
    required final String? initialValue,
  }) {
    return showModalBottomSheet<ProductMaterialResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) => ProductMaterialSheet(initialValue: initialValue),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final initialIsPreset =
        initialValue != null && kMaterialPresets.contains(initialValue);
    final selectedPreset = useState<String?>(initialIsPreset ? initialValue : null);
    final customController = useTextEditingController(
      text: initialIsPreset ? '' : (initialValue ?? ''),
    );
    useListenable(customController);

    void selectPreset(final String value) {
      if (selectedPreset.value == value) {
        selectedPreset.value = null;
      } else {
        selectedPreset.value = value;
        if (customController.text.isNotEmpty) customController.clear();
      }
    }

    void onCustomChanged(final String text) {
      if (text.isNotEmpty && selectedPreset.value != null) {
        selectedPreset.value = null;
      }
    }

    void done() {
      final preset = selectedPreset.value;
      final custom = customController.text.trim();
      final value = preset ?? (custom.isEmpty ? null : custom);
      Navigator.of(context).pop<ProductMaterialResult>((value: value));
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('選擇材質', style: textTheme.titleMedium),
                  TextButton(onPressed: done, child: const Text('完成')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: kMaterialPresets
                    .map(
                      (final p) => ChoiceChip(
                        label: Text(p),
                        selected: selectedPreset.value == p,
                        onSelected: (final _) => selectPreset(p),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '或自行輸入',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: customController,
                onChanged: onCustomChanged,
                textInputAction: TextInputAction.done,
                onSubmitted: (final _) => done(),
                decoration: const InputDecoration(hintText: '塑膠、再生纖維…'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
