import 'package:tryzeon/shared/utils/app_logger.dart';

class Result<T> {
  Result({required this.isSuccess, this.data, this.errorMessage});

  factory Result.success({final T? data}) {
    return Result(isSuccess: true, data: data);
  }

  factory Result.failure(
    final String title, {
    final dynamic error,
    final String? errorMessage,
  }) {
    final String message = errorMessage ?? '糟糕！$title, 請重試一次或重新登入。';

    if (error != null) {
      AppLogger.error('$title: ${error.toString()}');
    }

    return Result(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final T? data;
  final String? errorMessage;
}
