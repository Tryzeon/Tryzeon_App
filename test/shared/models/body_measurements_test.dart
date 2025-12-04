import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';

void main() {
  group('BodyMeasurements', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'height': 175.0,
        'weight': 70.0,
        'chest': 95.0,
        'waist': 80.0,
        'hips': 90.0,
        'shoulder_width': 45.0,
        'sleeve_length': 60.0,
      };

      final measurements = BodyMeasurements.fromJson(json);

      expect(measurements.height, 175.0);
      expect(measurements.weight, 70.0);
      expect(measurements.chest, 95.0);
      expect(measurements.waist, 80.0);
      expect(measurements.hips, 90.0);
      expect(measurements.shoulderWidth, 45.0);
      expect(measurements.sleeveLength, 60.0);
    });

    test('toJson converts object to valid JSON', () {
      const measurements = BodyMeasurements(
        height: 175.0,
        weight: 70.0,
        chest: 95.0,
        waist: 80.0,
        hips: 90.0,
        shoulderWidth: 45.0,
        sleeveLength: 60.0,
      );

      final json = measurements.toJson();

      expect(json['height'], 175.0);
      expect(json['weight'], 70.0);
      expect(json['chest'], 95.0);
      expect(json['waist'], 80.0);
      expect(json['hips'], 90.0);
      expect(json['shoulder_width'], 45.0);
      expect(json['sleeve_length'], 60.0);
    });

    test('operator [] returns correct values', () {
      const measurements = BodyMeasurements(
        height: 175.0,
        weight: 70.0,
        chest: 95.0,
        waist: 80.0,
        hips: 90.0,
        shoulderWidth: 45.0,
        sleeveLength: 60.0,
      );

      expect(measurements[MeasurementType.height], 175.0);
      expect(measurements[MeasurementType.weight], 70.0);
      expect(measurements[MeasurementType.chest], 95.0);
      expect(measurements[MeasurementType.waist], 80.0);
      expect(measurements[MeasurementType.hips], 90.0);
      expect(measurements[MeasurementType.shoulderWidth], 45.0);
      expect(measurements[MeasurementType.sleeveLength], 60.0);
    });

    test('MeasurementType enum has correct labels and icons', () {
      expect(MeasurementType.height.label, '身高 (cm)');
      expect(MeasurementType.height.icon, Icons.height_rounded);

      expect(MeasurementType.weight.label, '體重 (kg)');
      expect(MeasurementType.weight.icon, Icons.monitor_weight_outlined);
    });

    test('copyWith creates new instance with updated values', () {
      const original = BodyMeasurements(height: 170, weight: 60, chest: 90);

      final copy = original.copyWith(
        weight: 65, // Changed
        chest:
            null, // Keep original (null in parameters means "use this value" if passed, but here copyWith uses ?? this.field, so passing null usually means "keep original" if the parameter is nullable but default is null. Wait, let's check copyWith impl)
      );
      // Checking implementation of copyWith:
      // height: height ?? this.height
      // So if I pass null, it keeps the original.

      expect(copy.height, 170);
      expect(copy.weight, 65);
      expect(copy.chest, 90); // passed null, so keeps 90

      final copy2 = original.copyWith(chest: 95);
      expect(copy2.chest, 95);
    });

    test('getDirtyFields detects changes correctly', () {
      const original = BodyMeasurements(height: 170, weight: 60);

      // No changes
      expect(original.getDirtyFields(original), isEmpty);

      // Change one field
      const changedWeight = BodyMeasurements(height: 170, weight: 65);
      expect(original.getDirtyFields(changedWeight), {'weight': 65.0});

      // Change multiple fields
      const changedBoth = BodyMeasurements(height: 175, weight: 65);
      final diff = original.getDirtyFields(changedBoth);
      expect(diff['height'], 175.0);
      expect(diff['weight'], 65.0);

      // Add new field (was null, now has value)
      const addedChest = BodyMeasurements(height: 170, weight: 60, chest: 90);
      expect(original.getDirtyFields(addedChest), {'chest': 90.0});

      // Remove field (was value, now null? Wait, BodyMeasurements fields are nullable.
      // If target has null and original has value, getDirtyFields should detect it?
      // Logic: if (oldValue != newValue) updates[key] = newValue;
      // So yes, if newValue is null, it puts null in map.
      const removedWeight = BodyMeasurements(height: 170, weight: null);
      expect(original.getDirtyFields(removedWeight), {'weight': null});
    });
  });
}
