import 'dart:async' show TimeoutException;

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';

void main() {
  group('TimeoutFailure copy', () {
    test('does not claim the device is offline', () {
      final message = const TimeoutFailure().displayMessage();
      expect(message, isNot(contains('無網路')));
      expect(message, isNot(contains('網路設定')));
    });

    test('tells the user to retry and stay in the foreground', () {
      final message = const TimeoutFailure().displayMessage();
      expect(message, contains('重新嘗試'));
      expect(message, contains('前景'));
    });

    test('a caller-supplied message still wins', () {
      expect(const TimeoutFailure('自訂訊息').displayMessage(), '自訂訊息');
    });

    test('a real connectivity failure still reads as a network problem', () {
      expect(const NetworkFailure().displayMessage(), contains('無網路連線'));
    });

    test('a client deadline reaches the user as timeout copy, not network copy', () {
      final failure = mapExceptionToFailure(
        TimeoutException('deadline', const Duration(minutes: 7)),
      );
      expect(failure.displayMessage(), isNot(const NetworkFailure().displayMessage()));
    });
  });
}
