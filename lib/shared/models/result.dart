import 'dart:io';

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

  factory Result.failure(String message) {
    return Result(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
