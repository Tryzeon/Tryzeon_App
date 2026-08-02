import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';

/// Base Failure class
sealed class Failure extends Equatable {
  const Failure([this.message]);
  final String? message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure({final String? message, this.usagePayload}) : super(message);

  /// Raw `usage` snapshot from the edge function's 429 body, if present.
  /// Repositories populate this; orchestrators parse it into a `DailyUsage`.
  final Map<String, dynamic>? usagePayload;

  @override
  List<Object?> get props => [message, usagePayload];
}

class UserCanceledFailure extends Failure {
  const UserCanceledFailure([super.message]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

class AvatarMissingFailure extends Failure {
  const AvatarMissingFailure([super.message]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message]);
}

String? _functionErrorCode(final FunctionException e) {
  final details = e.details;
  if (details is! Map) return null;
  final code = details['code'];
  return code is String ? code : null;
}

/// Maps Exceptions to Failures
Failure mapExceptionToFailure(final Object e) {
  if (e is AuthException && e.code == 'otp_expired') {
    return const AuthFailure('驗證碼錯誤或過期');
  }

  // PGRST116 = no rows, 22P02 = invalid uuid syntax — both surface as `.code`.
  if (e is PostgrestException && (e.code == 'PGRST116' || e.code == '22P02')) {
    return const NotFoundFailure();
  }

  if (e is FunctionException) {
    if (e.status == 429) {
      final details = e.details;
      final usage = details is Map<String, dynamic>
          ? details['usage'] as Map<String, dynamic>?
          : null;
      return RateLimitFailure(usagePayload: usage);
    } else if (e.status == 422) {
      return const ServerFailure('AI 無法辨識圖片，請換一張試試');
    } else if (e.status == 400 && _functionErrorCode(e) == 'NO_AVATAR') {
      return const AvatarMissingFailure();
    }
  }

  return switch (e) {
    // Custom App Exceptions
    ServerException(message: final msg) => ServerFailure(msg),
    UnauthenticatedException(message: final msg) => AuthFailure(msg),
    UserCanceledException(message: final msg) => UserCanceledFailure(msg),
    NotFoundException(message: final msg) => NotFoundFailure(msg),

    // Supabase Exceptions
    PostgrestException() => const ServerFailure(),
    StorageException() => const ServerFailure(),
    FunctionException() => const ServerFailure(),
    AuthRetryableFetchException() => const NetworkFailure(),
    AuthException() => const AuthFailure(),

    // Network Exceptions
    SocketException() => const NetworkFailure(),
    // Client-side deadline (e.g. a long-running edge function killed at the
    // platform's wall-clock limit never responding, or a half-open socket left
    // by a suspended app that never delivers bytes, EOF or an error).
    TimeoutException() => const TimeoutFailure(),
    // http throws ClientException (often wrapping a SocketException) for
    // transport-level failures escaping Supabase.
    ClientException() => const NetworkFailure(),
    HandshakeException() => const NetworkFailure(),
    HttpException() => const ServerFailure(),
    TlsException() => const ServerFailure(),

    // Fallback
    _ => const UnknownFailure(),
  };
}
