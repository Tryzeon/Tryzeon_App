abstract class AppException implements Exception {
  const AppException([this.message]);
  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

class ServerException extends AppException {
  const ServerException([super.message, this.statusCode]);
  final int? statusCode;
}

class UnauthenticatedException extends AppException {
  const UnauthenticatedException([super.message]);
}

class UserCanceledException extends AppException {
  const UserCanceledException([super.message]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message]);
}
