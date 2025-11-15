import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class Result<T> {
  final bool isSuccess;
  final T? data;
  final File? file;
  final String? errorMessage;

  Result({
    required this.isSuccess,
    this.data,
    this.file,
    this.errorMessage,
  });

  factory Result.success({T? data, File? file}) {
    return Result(
      isSuccess: true,
      data: data,
      file: file,
    );
  }

  factory Result.failure(String message, {dynamic error}) {
    String errorMessage;

    // 如果有 error，檢查其類型
    if (error != null) {
      if (error is SocketException) {
        errorMessage = '無法連接網路，請檢查網路連線';
      } else if (error.toString().contains('TimeoutException')) {
        errorMessage = '連線逾時，請稍後再試';
      } else if (error is AuthException) {
        errorMessage = error.message;
      } else {
        errorMessage = '$message: ${error.toString()}';
      }
    } else {
      errorMessage = message;
    }

    return Result(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
