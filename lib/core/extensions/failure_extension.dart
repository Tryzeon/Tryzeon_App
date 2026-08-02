import 'package:flutter/widgets.dart';
import '../error/failures.dart';

extension FailureMessage on Failure {
  String displayMessage([final BuildContext? context]) {
    return switch (this) {
      NetworkFailure(message: final msg?) => msg,
      NetworkFailure() => '無網路連線，請檢查您的網路設定',

      ServerFailure(message: final msg?) => msg,
      ServerFailure() => '伺服器發生錯誤，請稍後再試',

      NotFoundFailure(message: final msg?) => msg,
      NotFoundFailure() => '找不到資源，可能已被移除或失效',

      AuthFailure(message: final msg?) => msg,
      AuthFailure() => '登入狀態異常，請稍後再試',

      ValidationFailure(message: final msg?) => msg,
      ValidationFailure() => '驗證失敗，請檢查您的輸入',

      RateLimitFailure(message: final msg?) => msg,
      RateLimitFailure() => '使用次數已達上限，請升級您的方案',

      AvatarMissingFailure(message: final msg?) => msg,
      AvatarMissingFailure() => '請先上傳個人照片才能開始試穿呦！',

      TimeoutFailure(message: final msg?) => msg,
      TimeoutFailure() => '處理時間過長而中斷，請重新嘗試；生成期間請讓 App 保持在前景',

      UserCanceledFailure(message: final msg?) => msg,
      UserCanceledFailure() => '',

      UnknownFailure(message: final msg?) => msg,
      UnknownFailure() => '發生未知錯誤，請稍後再試',
    };
  }
}

extension ErrorDisplayMessage on Object? {
  String displayMessage([final BuildContext? context]) {
    final error = this;

    if (error is Failure) {
      return error.displayMessage(context);
    }

    if (error is String && error.isNotEmpty) {
      return error;
    }

    return const UnknownFailure().displayMessage(context);
  }
}
