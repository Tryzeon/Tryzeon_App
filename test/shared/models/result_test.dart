import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/shared/models/result.dart';

void main() {
  group('Result', () {
    test('success factory creates successful result', () {
      final result = Result.success(data: 'test data');

      expect(result.isSuccess, true);
      expect(result.data, 'test data');
      expect(result.errorMessage, null);
    });

    test('failure factory creates failed result', () {
      final result = Result.failure('Test Error');

      expect(result.isSuccess, false);
      expect(result.data, null);
      expect(result.errorMessage, contains('Test Error'));
      expect(result.errorMessage, contains('糟糕！'));
    });
  });
}
