import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';

void main() {
  group('mapExceptionToFailure - not found', () {
    test('maps NotFoundException to NotFoundFailure', () {
      final failure = mapExceptionToFailure(const NotFoundException());
      expect(failure, isA<NotFoundFailure>());
    });

    test('preserves NotFoundException message', () {
      final failure = mapExceptionToFailure(const NotFoundException('沒有這個'));
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, '沒有這個');
    });

    test('maps PostgrestException PGRST116 (no rows) to NotFoundFailure', () {
      final failure = mapExceptionToFailure(
        const PostgrestException(message: 'no rows', code: 'PGRST116'),
      );
      expect(failure, isA<NotFoundFailure>());
    });

    test('maps PostgrestException 22P02 (invalid uuid) to NotFoundFailure', () {
      final failure = mapExceptionToFailure(
        const PostgrestException(message: 'invalid input', code: '22P02'),
      );
      expect(failure, isA<NotFoundFailure>());
    });

    test('maps 22P02 embedded in the message body (code is HTTP 400)', () {
      final failure = mapExceptionToFailure(
        const PostgrestException(
          message:
              '{"code":"22P02","details":null,"hint":null,'
              '"message":"invalid input syntax for type uuid"}',
          code: '400',
        ),
      );
      expect(failure, isA<NotFoundFailure>());
    });

    test('maps other PostgrestException codes to ServerFailure', () {
      final failure = mapExceptionToFailure(
        const PostgrestException(message: 'boom', code: '500'),
      );
      expect(failure, isA<ServerFailure>());
    });
  });
}
