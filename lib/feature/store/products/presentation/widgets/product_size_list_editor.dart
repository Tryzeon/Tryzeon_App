import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/garment_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_size_voice_input.dart';

class ProductSizeListEditor extends StatelessWidget {
  const ProductSizeListEditor({
    super.key,
    required this.entries,
    required this.visibleTypes,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.onAdd,
    required this.onRemove,
    required this.voiceStatus,
    required this.onVoicePressed,
  });

  final List<ProductSizeEntryController> entries;

  /// The dimensions relevant to the selected categories — the only
  /// measurement fields rendered per size card.
  final List<GarmentMeasurementType> visibleTypes;

  final MeasurementUnit selectedUnit;
  final ValueChanged<MeasurementUnit> onUnitChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final SizeVoiceStatus voiceStatus;
  final VoidCallback onVoicePressed;

  static const List<String> _standardSizes = ['S', 'M', 'L', 'XL', '2XL'];

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: voiceStatus == SizeVoiceStatus.uploading ? null : onVoicePressed,
              visualDensity: VisualDensity.compact,
              tooltip: '語音輸入尺寸',
              icon: switch (voiceStatus) {
                SizeVoiceStatus.uploading => SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: AppStroke.regular,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizeVoiceStatus.recording => Icon(
                  Icons.stop_circle_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
                SizeVoiceStatus.idle => Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
              },
            ),
            Expanded(
              child: Text(
                voiceStatus == SizeVoiceStatus.recording
                    ? '錄音中…再按一下停止'
                    : '可語音輸入：例「M 號，胸寬五十公分，衣長七十二」',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<MeasurementUnit>(
                value: selectedUnit,
                isDense: true,
                style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                items: MeasurementUnit.values
                    .map(
                      (final unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (final v) {
                  if (v != null) onUnitChanged(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.smMd),
        if (entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: Text(
                  '尚未新增尺寸',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.smMd),
            _SizeCard(
              index: i,
              entry: entries[i],
              visibleTypes: visibleTypes,
              selectedUnit: selectedUnit,
              standardSizes: _standardSizes,
              onRemove: () => onRemove(i),
            ),
          ],
        const SizedBox(height: AppSpacing.smMd),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              side: BorderSide(color: colorScheme.outline, width: AppStroke.regular),
              textStyle: textTheme.labelMedium,
            ),
            child: const Text('+ 新增尺寸'),
          ),
        ),
      ],
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.index,
    required this.entry,
    required this.visibleTypes,
    required this.selectedUnit,
    required this.standardSizes,
    required this.onRemove,
  });

  final int index;
  final ProductSizeEntryController entry;
  final List<GarmentMeasurementType> visibleTypes;
  final MeasurementUnit selectedUnit;
  final List<String> standardSizes;
  final VoidCallback onRemove;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '尺寸 ${(index + 1).toString().padLeft(2, '0')}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  tooltip: '移除',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: entry.nameController,
              builder: (final context, final value, final _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: entry.nameController,
                    decoration: const InputDecoration(hintText: 'XS / M / US 10 …'),
                    validator: AppValidators.validateSizeName,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: standardSizes.map((final size) {
                      final isSelected = entry.nameController.text == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (final s) {
                          if (s) entry.nameController.text = size;
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...visibleTypes.map(
              (final type) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.smMd),
                child: _MeasurementRow(
                  type: type,
                  unit: selectedUnit,
                  valueController: entry.measurementControllers[type]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.type,
    required this.unit,
    required this.valueController,
  });

  final GarmentMeasurementType type;
  final MeasurementUnit unit;
  final TextEditingController valueController;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final label = '${type.label} · ${unit.symbol}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: valueController,
          decoration: const InputDecoration(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
          validator: AppValidators.validateMeasurement,
        ),
      ],
    );
  }
}
