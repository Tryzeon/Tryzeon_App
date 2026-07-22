import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';

class ProductSizeEntryController {
  ProductSizeEntryController({
    this.id,
    final String name = '',
    final Measurements? measurements,
  }) : nameController = TextEditingController(text: name) {
    for (final type in MeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: measurements?.getValue(type)?.toString() ?? '',
      );
    }
  }

  factory ProductSizeEntryController.fromProductSize(final ProductSize size) {
    return ProductSizeEntryController(
      id: size.id,
      name: size.name,
      measurements: size.measurements,
    );
  }

  factory ProductSizeEntryController.fromParsedSize(
    final ParsedSize parsed, {
    required final MeasurementUnit targetUnit,
  }) {
    final controller = ProductSizeEntryController(name: parsed.name);

    String format(final double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    for (final entry in parsed.measurements.entries) {
      final m = entry.value;
      final factor = m.unit.toCmFactor / targetUnit.toCmFactor;
      controller.measurementControllers[entry.key]?.text = format(m.value * factor);
    }

    return controller;
  }

  final String? id;
  final TextEditingController nameController;
  final Map<MeasurementType, TextEditingController> measurementControllers = {};

  double? _parseAndConvert(final String? text, final MeasurementUnit unit) {
    if (text == null || text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return double.parse((value * unit.toCmFactor).toStringAsFixed(1));
  }

  Measurements _buildMeasurements({required final MeasurementUnit unit}) {
    double? getValue(final MeasurementType type) =>
        _parseAndConvert(measurementControllers[type]?.text, unit);

    return Measurements(
      height: getValue(MeasurementType.height),
      shoulder: getValue(MeasurementType.shoulder),
      chest: getValue(MeasurementType.chest),
      sleeve: getValue(MeasurementType.sleeve),
      waist: getValue(MeasurementType.waist),
      hips: getValue(MeasurementType.hips),
    );
  }

  /// The size as the store owner currently has it in the form: [ExistingSizeItem]
  /// when it came from the product, [NewSizeItem] when they just added it.
  SizeItem toSizeItem({required final MeasurementUnit unit}) {
    final measurements = _buildMeasurements(unit: unit);
    final sizeId = id;

    return sizeId == null
        ? SizeItem.newSize(name: nameController.text, measurements: measurements)
        : SizeItem.existing(
            id: sizeId,
            name: nameController.text,
            measurements: measurements,
          );
  }

  void convertValues({
    required final MeasurementUnit fromUnit,
    required final MeasurementUnit toUnit,
  }) {
    if (fromUnit == toUnit) return;

    final factor = fromUnit.toCmFactor / toUnit.toCmFactor;

    void convert(final TextEditingController controller) {
      final value = double.tryParse(controller.text);
      if (value == null) return;
      controller.text = (value * factor)
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
    }

    measurementControllers.values.forEach(convert);
  }

  void dispose() {
    nameController.dispose();
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
  }
}
