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

    test('fromTypeMap creates object correctly', () {
      final map = {
        MeasurementType.height: 180.0,
        MeasurementType.weight: 75.0,
        MeasurementType.chest: 100.0,
        MeasurementType.waist: 85.0,
        MeasurementType.hips: 95.0,
        MeasurementType.shoulderWidth: 48.0,
        MeasurementType.sleeveLength: 62.0,
      };

      final measurements = BodyMeasurements.fromTypeMap(map);

      expect(measurements.height, 180.0);
      expect(measurements.weight, 75.0);
      expect(measurements.chest, 100.0);
      expect(measurements.waist, 85.0);
      expect(measurements.hips, 95.0);
      expect(measurements.shoulderWidth, 48.0);
      expect(measurements.sleeveLength, 62.0);
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
  });
}
