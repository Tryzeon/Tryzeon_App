import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/utils/json_diff.dart';

void main() {
  group('jsonDiff', () {
    test('returns an empty map when nothing changed', () {
      final original = {'name': 'Tee', 'price': 100.0};
      final target = {'name': 'Tee', 'price': 100.0};

      expect(jsonDiff(original, target), isEmpty);
    });

    test('returns only the keys whose value changed', () {
      final original = {'name': 'Tee', 'price': 100.0, 'material': 'cotton'};
      final target = {'name': 'Tee', 'price': 120.0, 'material': 'cotton'};

      expect(jsonDiff(original, target), {'price': 120.0});
    });

    test('includes a key cleared to null', () {
      final original = {'material': 'cotton'};
      final target = {'material': null};

      final changes = jsonDiff(original, target);

      expect(changes.containsKey('material'), isTrue);
      expect(changes['material'], isNull);
    });

    test('omits a key that was null and stayed null', () {
      final original = {'material': null, 'fit': 'regular'};
      final target = {'material': null, 'fit': 'regular'};

      expect(jsonDiff(original, target), isEmpty);
    });

    test('includes a key that went from null to a value', () {
      final original = {'material': null};
      final target = {'material': 'wool'};

      expect(jsonDiff(original, target), {'material': 'wool'});
    });

    test('treats a reordered list as a change by default', () {
      final original = {
        'image_paths': ['a.jpg', 'b.jpg'],
      };
      final target = {
        'image_paths': ['b.jpg', 'a.jpg'],
      };

      expect(jsonDiff(original, target), {
        'image_paths': ['b.jpg', 'a.jpg'],
      });
    });

    test('reports a nested map when an inner value differs', () {
      final original = {
        'measurements': {'chest': 50.0, 'waist': 40.0},
      };
      final target = {
        'measurements': {'chest': 52.0, 'waist': 40.0},
      };

      expect(jsonDiff(original, target), {
        'measurements': {'chest': 52.0, 'waist': 40.0},
      });
    });

    test('omits a nested map whose contents are unchanged', () {
      final original = {
        'measurements': {'chest': 50.0, 'waist': 40.0},
      };
      final target = {
        'measurements': {'chest': 50.0, 'waist': 40.0},
      };

      expect(jsonDiff(original, target), isEmpty);
    });

    test('reports a nested map that dropped a key', () {
      final original = {
        'measurements': {'chest': 50.0, 'waist': 40.0},
      };
      final target = {
        'measurements': {'chest': 50.0},
      };

      expect(jsonDiff(original, target), {
        'measurements': {'chest': 50.0},
      });
    });

    test('ignores keys that are absent from the target', () {
      final original = {'name': 'Tee', 'id': 'p1'};
      final target = {'name': 'Tee'};

      expect(jsonDiff(original, target), isEmpty);
    });
  });
}
