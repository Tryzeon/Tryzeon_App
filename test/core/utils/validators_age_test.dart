import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/validators.dart';

void main() {
  test('empty value is allowed (optional field)', () {
    expect(AppValidators.validateAge(''), isNull);
    expect(AppValidators.validateAge('   '), isNull);
    expect(AppValidators.validateAge(null), isNull);
  });

  test('non-numeric value is rejected', () {
    expect(AppValidators.validateAge('abc'), isNotNull);
  });

  test('values inside 4..100 are accepted', () {
    expect(AppValidators.validateAge('4'), isNull);
    expect(AppValidators.validateAge('25'), isNull);
    expect(AppValidators.validateAge('100'), isNull);
  });

  test('values outside 4..100 are rejected', () {
    expect(AppValidators.validateAge('3'), isNotNull);
    expect(AppValidators.validateAge('101'), isNotNull);
  });
}
