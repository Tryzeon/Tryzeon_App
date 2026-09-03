import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/garment_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_size_entry_controller.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_size_manager.dart';

// 表格幾何：左欄與格子必須等高才對得齊，所以固定而非依內容撐開。
// 列高含一行錯誤訊息的空間，讓有無錯誤的列不會改變高度。
const double _labelColumnWidth = 40;
// 格子寬度由最長的錯誤訊息決定（`40–200cm`），窄一點就會被截成刪節號。
const double _cellWidth = 65;
const double _rowHeight = 62;
const double _headerHeight = 32;

class ProductSizeMatrixEditor extends HookWidget {
  const ProductSizeMatrixEditor({
    super.key,
    required this.manager,
    required this.visibleTypes,
  });

  final ProductSizeManager manager;

  final List<GarmentMeasurementType> visibleTypes;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SizeChipRow(
          manager: manager,
          onAddCustom: () => _promptCustomSize(context, manager),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: _UnitSelector(
            selectedUnit: manager.selectedUnit,
            onUnitChanged: manager.changeUnit,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (manager.sizeEntries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: Text(
                  '請先選擇尺寸',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          _MatrixTable(
            entries: manager.sizeEntries,
            visibleTypes: visibleTypes,
            unit: manager.selectedUnit,
          ),
      ],
    );
  }

  Future<void> _promptCustomSize(
    final BuildContext context,
    final ProductSizeManager manager,
  ) async {
    final result = await showTextInputDialog(
      context: context,
      title: '新增自訂尺寸',
      okLabel: '新增',
      cancelLabel: '取消',
      textFields: [
        DialogTextField(
          hintText: '例如 4XL、US 10',
          maxLength: 8,
          validator: (final value) {
            final emptyError = AppValidators.validateSizeName(value);
            if (emptyError != null) return emptyError;
            if (manager.hasLabel(value!.trim())) return '已有這個尺寸';
            return null;
          },
        ),
      ],
    );
    final name = result?.firstOrNull;
    if (name != null) manager.addCustom(name);
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.selectedUnit, required this.onUnitChanged});

  final MeasurementUnit selectedUnit;
  final ValueChanged<MeasurementUnit> onUnitChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DropdownButtonHideUnderline(
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
              (final unit) =>
                  DropdownMenuItem(value: unit, child: Text(unit.label.toUpperCase())),
            )
            .toList(),
        onChanged: (final v) {
          if (v != null) onUnitChanged(v);
        },
      ),
    );
  }
}

class _SizeChipRow extends StatelessWidget {
  const _SizeChipRow({required this.manager, required this.onAddCustom});

  final ProductSizeManager manager;
  final VoidCallback onAddCustom;

  @override
  Widget build(final BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in StandardSizeLabel.values)
          FilterChip(
            label: Text(label.display),
            selected: manager.isSelected(label),
            showCheckmark: false,
            onSelected: (final _) => manager.toggleStandard(label),
          ),
        for (final custom in manager.customLabels)
          FilterChip(
            label: Text(custom),
            selected: true,
            showCheckmark: false,
            onSelected: (final _) => manager.removeLabel(custom),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 14),
          label: const Text('自訂'),
          onPressed: onAddCustom,
        ),
      ],
    );
  }
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({
    required this.entries,
    required this.visibleTypes,
    required this.unit,
  });

  final List<ProductSizeEntryController> entries;
  final List<GarmentMeasurementType> visibleTypes;
  final MeasurementUnit unit;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final textScaler = MediaQuery.textScalerOf(context);
    final rowHeight = textScaler.scale(_rowHeight);
    final headerHeight = textScaler.scale(_headerHeight);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _labelColumnWidth,
          child: Column(
            children: [
              SizedBox(height: headerHeight),
              for (final entry in entries)
                SizedBox(
                  key: ObjectKey(entry),
                  height: rowHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entry.label,
                      style: textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    children: [
                      for (final type in visibleTypes)
                        SizedBox(
                          width: _cellWidth,
                          child: Center(
                            child: Text(
                              type.label,
                              style: textTheme.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final entry in entries)
                  SizedBox(
                    key: ObjectKey(entry),
                    height: rowHeight,
                    child: Row(
                      children: [
                        for (final type in visibleTypes)
                          _MeasurementCell(
                            controller: entry.measurementControllers[type]!,
                            type: type,
                            unit: unit,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MeasurementCell extends StatelessWidget {
  const _MeasurementCell({
    required this.controller,
    required this.type,
    required this.unit,
  });

  final TextEditingController controller;
  final GarmentMeasurementType type;
  final MeasurementUnit unit;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: _cellWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        child: TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
          validator: (final value) => AppValidators.validateRange(
            value,
            min: type.minCm,
            max: type.maxCm,
            unitSuffix: 'cm',
            scale: unit.toCmFactor,
            compact: true,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.sm,
            ),
            errorStyle: TextStyle(fontSize: 9, height: 1.1),
            errorMaxLines: 1,
          ),
        ),
      ),
    );
  }
}
