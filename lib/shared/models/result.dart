class Result<T> {
  Result({required this.isSuccess, this.data, this.errorMessage});

  factory Result.success({final T? data}) {
    return Result(isSuccess: true, data: data);
  }

  factory Result.failure(final String message) {
    return Result(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final T? data;
  final String? errorMessage;
}
