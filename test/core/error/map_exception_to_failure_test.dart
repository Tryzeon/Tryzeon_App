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

    test('FunctionException SERVICE_BUSY maps to ServiceBusyFailure', () {
      expect(
        mapExceptionToFailure(
          const FunctionException(
            status: 503,
            details: {'error': 'Service is busy, please try again shortly', 'code': 'SERVICE_BUSY'},
          ),
        ),
        isA<ServiceBusyFailure>(),
      );
    });

    test('the code decides, not the status it was rendered with', () {
      // The edge functions keep one code per failure precisely so this is the
      // identity; 503 is only how the HTTP transport spells it today, and the
      // chat stream reports the same failure with no status at all.
      expect(
        mapExceptionToFailure(
          const FunctionException(status: 529, details: {'code': 'SERVICE_BUSY'}),
        ),
        isA<ServiceBusyFailure>(),
      );
    });

    test('FunctionException AI_GENERATION_FAILED keeps its own copy', () {
      final failure = mapExceptionToFailure(
        const FunctionException(status: 422, details: {'code': 'AI_GENERATION_FAILED'}),
      );
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'AI 無法辨識圖片，請換一張試試');
    });

    test('FunctionException RATE_LIMIT_EXCEEDED carries usage', () {
      final failure = mapExceptionToFailure(
        const FunctionException(
          status: 429,
          details: {
            'code': 'RATE_LIMIT_EXCEEDED',
            'usage': {'used': 3, 'limit': 3},
          },
        ),
      );
      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).usagePayload, {'used': 3, 'limit': 3});
    });

    test('a malformed body is decoded, not thrown on', () {
      // This is the function that turns exceptions into Failures — a body whose
      // shape surprises us must not become a second exception.
      expect(
        mapExceptionToFailure(const FunctionException(status: 500, details: 'not an object')),
        isA<ServerFailure>(),
      );
      expect(
        mapExceptionToFailure(const FunctionException(status: 500, details: {'code': 42})),
        isA<ServerFailure>(),
      );
      final failure = mapExceptionToFailure(
        const FunctionException(
          status: 429,
          details: {'code': 'RATE_LIMIT_EXCEEDED', 'usage': 'not a map'},
        ),
      );
      expect((failure as RateLimitFailure).usagePayload, isNull);
    });

    test('a bare 429 with no code of ours is still a rate limit', () {
      // `jsonRateLimited` sends the code and the usage together, so a 429
      // without one has neither: it never reached our handler.
      final failure = mapExceptionToFailure(const FunctionException(status: 429));
      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).usagePayload, isNull);
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

    // A client-side deadline is not a connectivity problem: reporting it as
    // NetworkFailure both misleads the user and puts a long generation job on
    // main.dart's NetworkFailure retry path.
    test('TimeoutException maps to TimeoutFailure, not NetworkFailure', () {
      final failure = mapExceptionToFailure(
        TimeoutException('deadline', const Duration(minutes: 7)),
      );
      expect(failure, isA<TimeoutFailure>());
      expect(failure, isNot(isA<NetworkFailure>()));
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
