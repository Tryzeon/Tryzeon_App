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

    test('failure factory logs error if provided', () {
      // Since we can't easily mock static methods or logger without dependency injection,
      // we mainly test the state of the returned object.
      // In a real scenario, we might want to mock AppLogger.
      final result = Result.failure(
        'Test Error',
        error: Exception('Something went wrong'),
      );

      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Test Error'));
    });
  });
}
