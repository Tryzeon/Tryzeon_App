import 'dart:io';

class Result<T> {
  final bool success;
  final T? data;
  final File? file;
  final String? errorMessage;

  Result({
    required this.success,
    this.data,
    this.file,
    this.errorMessage,
  });

  factory Result.success({T? data, File? file}) {
    return Result(
      success: true,
      data: data,
      file: file,
    );
  }

  factory Result.failure(String message) {
    return Result(
      success: false,
      errorMessage: message,
    );
  }
}
