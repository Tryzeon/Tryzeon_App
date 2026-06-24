import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/measurements/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_size_voice_input.dart';

class ProductSizeListEditor extends StatelessWidget {
  const ProductSizeListEditor({
    super.key,
    required this.entries,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.onAdd,
    required this.onRemove,
    required this.voiceStatus,
    required this.onVoicePressed,
  });

  final List<ProductSizeEntryController> entries;
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
                    : '可語音輸入：例「M 號，胸圍九十公分，腰圍七十二」',
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
    required this.selectedUnit,
    required this.standardSizes,
    required this.onRemove,
  });

  final int index;
  final ProductSizeEntryController entry;
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
            ...MeasurementType.values.map(
              (final type) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.smMd),
                child: _MeasurementRow(
                  type: type,
                  unit: selectedUnit,
                  valueController: entry.measurementControllers[type]!,
                  offsetController: entry.offsetControllers[type]!,
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
    required this.offsetController,
  });

  final MeasurementType type;
  final MeasurementUnit unit;
  final TextEditingController valueController;
  final TextEditingController offsetController;

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
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: valueController,
                decoration: const InputDecoration(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                validator: AppValidators.validateMeasurement,
              ),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              flex: 2,
              child: _OffsetStepper(
                offsetController: offsetController,
                valueController: valueController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OffsetStepper extends StatelessWidget {
  const _OffsetStepper({required this.offsetController, required this.valueController});

  final TextEditingController offsetController;
  final TextEditingController valueController;

  void _update(final double delta) {
    final current = double.tryParse(offsetController.text) ?? 0.0;
    final next = (current + delta).clamp(0.0, 50.0);
    offsetController.text = next.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FormField<String>(
      initialValue: offsetController.text,
      validator: (final v) => AppValidators.validateOffset(
        offsetValue: v,
        measurementValue: valueController.text,
      ),
      builder: (final field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: const InputDecoration(contentPadding: EdgeInsets.zero),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _update(-0.5);
                    field.didChange(offsetController.text);
                  },
                ),
                Container(
                  width: AppStroke.thin,
                  height: AppSpacing.lg,
                  color: colorScheme.outline,
                ),
                Expanded(
                  child: TextField(
                    controller: offsetController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      hintText: '±0.0',
                    ),
                    onChanged: field.didChange,
                  ),
                ),
                Container(
                  width: AppStroke.thin,
                  height: AppSpacing.lg,
                  color: colorScheme.outline,
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _update(0.5);
                    field.didChange(offsetController.text);
                  },
                ),
              ],
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.xs),
              child: Text(
                field.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
