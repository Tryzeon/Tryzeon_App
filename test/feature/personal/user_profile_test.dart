import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/personal/presentation/pages/settings/data/profile_service.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';

void main() {
  group('UserProfile', () {
    final measurements = const BodyMeasurements(height: 170, weight: 60);
    final profile = UserProfile(
      userId: 'user_123',
      name: 'Test User',
      measurements: measurements,
    );

    test('fromJson parses valid JSON correctly', () {
      final json = {
        'user_id': 'user_123',
        'name': 'Test User',
        'height': 170.0,
        'weight': 60.0,
      };

      final result = UserProfile.fromJson(json);

      expect(result.userId, 'user_123');
      expect(result.name, 'Test User');
      expect(result.measurements.height, 170.0);
      expect(result.measurements.weight, 60.0);
    });

    test('toJson converts object to valid JSON', () {
      final json = profile.toJson();

      expect(json['user_id'], 'user_123');
      expect(json['name'], 'Test User');
      expect(json['height'], 170.0);
      expect(json['weight'], 60.0);
    });

    test('copyWith creates new instance with updated values', () {
      final copy = profile.copyWith(name: 'New Name');

      expect(copy.userId, profile.userId); // Unchanged
      expect(copy.name, 'New Name'); // Changed
      expect(copy.measurements, profile.measurements); // Unchanged

      final copyMeasurements = profile.copyWith(
        measurements: const BodyMeasurements(height: 180),
      );
      expect(copyMeasurements.measurements.height, 180);
    });

    test('getDirtyFields detects changes correctly', () {
      // Case 1: No changes
      expect(profile.getDirtyFields(profile), isEmpty);

      // Case 2: Name changed
      final nameChanged = profile.copyWith(name: 'New Name');
      expect(profile.getDirtyFields(nameChanged), {'name': 'New Name'});

      // Case 3: Measurement changed
      final measureChanged = profile.copyWith(
        measurements: measurements.copyWith(weight: 65),
      );
      // Note: getDirtyFields flattens measurements into the map
      expect(profile.getDirtyFields(measureChanged), {'weight': 65.0});

      // Case 4: Multiple changes
      final multiChanged = UserProfile(
        userId: 'user_123',
        name: 'New Name',
        measurements: const BodyMeasurements(height: 175, weight: 60),
      );
      final diff = profile.getDirtyFields(multiChanged);
      expect(diff['name'], 'New Name');
      expect(diff['height'], 175.0);
    });
  });
}
