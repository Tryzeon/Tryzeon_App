import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';

class Result<T> {
  Result({required this.isSuccess, this.data, this.errorMessage});

  factory Result.success({final T? data}) {
    return Result(isSuccess: true, data: data);
  }

  factory Result.failure(final String title, {final dynamic error}) {
    String message = title;

    if (error != null) {
      String errorMessage = '';
      if (error is FunctionException) {
        errorMessage = (error.details as Map<String, dynamic>?)?['message'];
      } else if (error is AuthException) {
        errorMessage = error.message;
      } else if (error is StorageException) {
        errorMessage = error.message;
      } else if (error is SocketException) {
        errorMessage = '發生錯誤，請檢查網路連接或稍後再試。';
      } else {
        errorMessage = '發生錯誤，請稍後再試。';
        AppLogger.error('$title: ${error.toString()}');
      }

      message = '$title: $errorMessage';
    }

    return Result(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final T? data;
  final String? errorMessage;
}
