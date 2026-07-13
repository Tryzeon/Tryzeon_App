import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class ProductSizeEntryController {
  ProductSizeEntryController({
    this.id,
    this.createdAt,
    this.updatedAt,
    final String name = '',
    final Measurements? measurements,
  }) : nameController = TextEditingController(text: name) {
    for (final type in MeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: measurements?.getValue(type)?.toString() ?? '',
      );

      final offsetValue = measurements?.getOffset(type);
      offsetControllers[type] = TextEditingController(
        text: offsetValue?.toString() ?? '',
      );
    }
  }

  factory ProductSizeEntryController.fromProductSize(final ProductSize size) {
    return ProductSizeEntryController(
      id: size.id,
      createdAt: size.createdAt,
      updatedAt: size.updatedAt,
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
      final offset = m.offset;
      if (offset != null) {
        controller.offsetControllers[entry.key]?.text = format(offset * factor);
      }
    }

    return controller;
  }

  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TextEditingController nameController;
  final Map<MeasurementType, TextEditingController> measurementControllers = {};
  final Map<MeasurementType, TextEditingController> offsetControllers = {};

  double? _parseAndConvert(final String? text, final MeasurementUnit unit) {
    if (text == null || text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return double.parse((value * unit.toCmFactor).toStringAsFixed(1));
  }

  Measurements _buildMeasurements({required final MeasurementUnit unit}) {
    double? getValue(final MeasurementType type) =>
        _parseAndConvert(measurementControllers[type]?.text, unit);

    double? getOffset(final MeasurementType type) =>
        _parseAndConvert(offsetControllers[type]?.text.trim(), unit);

    return Measurements(
      height: getValue(MeasurementType.height),
      shoulder: getValue(MeasurementType.shoulder),
      chest: getValue(MeasurementType.chest),
      sleeve: getValue(MeasurementType.sleeve),
      waist: getValue(MeasurementType.waist),
      hips: getValue(MeasurementType.hips),
      heightOffset: getOffset(MeasurementType.height),
      shoulderOffset: getOffset(MeasurementType.shoulder),
      chestOffset: getOffset(MeasurementType.chest),
      sleeveOffset: getOffset(MeasurementType.sleeve),
      waistOffset: getOffset(MeasurementType.waist),
      hipsOffset: getOffset(MeasurementType.hips),
    );
  }

  CreateProductSizeParams toCreateProductSizeParams({
    required final MeasurementUnit unit,
  }) {
    return CreateProductSizeParams(
      name: nameController.text,
      measurements: _buildMeasurements(unit: unit),
    );
  }

  ProductSize toProductSize(
    final String productId, {
    required final MeasurementUnit unit,
  }) {
    return ProductSize(
      id: id!,
      productId: productId,
      name: nameController.text,
      measurements: _buildMeasurements(unit: unit),
      createdAt: createdAt!,
      updatedAt: updatedAt!,
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
    offsetControllers.values.forEach(convert);
  }

  void dispose() {
    nameController.dispose();
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
    for (final controller in offsetControllers.values) {
      controller.dispose();
    }
  }
}
