import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('AuthException with otp_expired code maps to AuthFailure', () {
      final failure = mapExceptionToFailure(
        const AuthException('expired', code: 'otp_expired'),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, '驗證碼錯誤或過期');
    });

    test('AuthException without otp_expired code falls back to AuthFailure', () {
      final failure = mapExceptionToFailure(
        const AuthException('bad password', code: 'invalid_credentials'),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, isNull);
    });

    test('AuthRetryableFetchException maps to NetworkFailure', () {
      expect(mapExceptionToFailure(AuthRetryableFetchException()), isA<NetworkFailure>());
    });

    test('PostgrestException PGRST116 (no rows) maps to NotFoundFailure', () {
      expect(
        mapExceptionToFailure(
          const PostgrestException(message: 'no rows', code: 'PGRST116'),
        ),
        isA<NotFoundFailure>(),
      );
    });

    test('PostgrestException 22P02 (invalid uuid) maps to NotFoundFailure', () {
      expect(
        mapExceptionToFailure(
          const PostgrestException(message: 'invalid input', code: '22P02'),
        ),
        isA<NotFoundFailure>(),
      );
    });

    test('PostgrestException with other code maps to ServerFailure', () {
      expect(
        mapExceptionToFailure(const PostgrestException(message: 'boom', code: '500')),
        isA<ServerFailure>(),
      );
    });

    test('FunctionException 429 maps to RateLimitFailure with usage payload', () {
      final failure = mapExceptionToFailure(
        const FunctionException(
          status: 429,
          details: {
            'usage': {'used': 3, 'limit': 3},
          },
        ),
      );
      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).usagePayload, {'used': 3, 'limit': 3});
    });

    test('FunctionException 422 maps to ServerFailure', () {
      expect(
        mapExceptionToFailure(const FunctionException(status: 422)),
        isA<ServerFailure>(),
      );
    });

    test('ClientException maps to NetworkFailure', () {
      expect(
        mapExceptionToFailure(ClientException('SocketException: failed host lookup')),
        isA<NetworkFailure>(),
      );
    });

    test('SocketException maps to NetworkFailure', () {
      expect(
        mapExceptionToFailure(const SocketException('no route to host')),
        isA<NetworkFailure>(),
      );
    });

    test('TimeoutException maps to NetworkFailure', () {
      expect(
        mapExceptionToFailure(TimeoutException('deadline', const Duration(minutes: 2))),
        isA<NetworkFailure>(),
      );
    });

    test('custom ServerException preserves its message', () {
      final failure = mapExceptionToFailure(const ServerException('down'));
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'down');
    });

    test('unrecognised error maps to UnknownFailure', () {
      expect(mapExceptionToFailure(const FormatException('nope')), isA<UnknownFailure>());
    });

    test('FunctionException 400 NO_AVATAR maps to AvatarMissingFailure', () {
      expect(
        mapExceptionToFailure(
          const FunctionException(
            status: 400,
            details: {'error': 'No model photo on file', 'code': 'NO_AVATAR'},
          ),
        ),
        isA<AvatarMissingFailure>(),
      );
    });

    test('FunctionException 400 with another code maps to ServerFailure', () {
      expect(
        mapExceptionToFailure(
          const FunctionException(
            status: 400,
            details: {'error': 'bad body', 'code': 'VALIDATION_ERROR'},
          ),
        ),
        isA<ServerFailure>(),
      );
    });

    test('FunctionException 400 with no details maps to ServerFailure', () {
      expect(
        mapExceptionToFailure(const FunctionException(status: 400)),
        isA<ServerFailure>(),
      );
    });
  });
}
