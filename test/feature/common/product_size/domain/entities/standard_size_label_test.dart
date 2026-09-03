import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';

void main() {
  group('StandardSizeLabel.tryParse', () {
    test('recognizes the standard spellings, ignoring case and whitespace', () {
      expect(StandardSizeLabel.tryParse('M'), StandardSizeLabel.m);
      expect(StandardSizeLabel.tryParse(' m '), StandardSizeLabel.m);
      expect(StandardSizeLabel.tryParse('xl'), StandardSizeLabel.xl);
      expect(StandardSizeLabel.tryParse('2XL'), StandardSizeLabel.xxl);
    });

    test('does not fold aliases: XXL is a custom size, not 2XL', () {
      expect(StandardSizeLabel.tryParse('XXL'), isNull);
      expect(StandardSizeLabel.xxl.display, '2XL');
    });

    test('free size matches the literal only; F/free are always custom sizes', () {
      expect(StandardSizeLabel.tryParse('均碼'), StandardSizeLabel.free);
      expect(StandardSizeLabel.tryParse('F'), isNull);
      expect(StandardSizeLabel.tryParse('free'), isNull);
      expect(StandardSizeLabel.tryParse('One Size'), isNull);
    });

    test('an unrecognized name returns null, meaning a custom size', () {
      expect(StandardSizeLabel.tryParse('4XL'), isNull);
      expect(StandardSizeLabel.tryParse('US 10'), isNull);
      expect(StandardSizeLabel.tryParse(''), isNull);
    });
  });

  group('StandardSizeLabel.matchKeyOf', () {
    test('only trims and upper-cases, so case differences are the same size', () {
      expect(StandardSizeLabel.matchKeyOf(' m '), 'M');
      expect(StandardSizeLabel.matchKeyOf('us 10'), 'US 10');
    });

    test('aliases are no longer folded: XXL and 2XL are different keys', () {
      expect(
        StandardSizeLabel.matchKeyOf('XXL'),
        isNot(StandardSizeLabel.matchKeyOf('2XL')),
      );
    });
  });

  group('sizeRowInsertIndex', () {
    test('inserts at the front of an empty list', () {
      expect(sizeRowInsertIndex(const [], 'M'), 0);
    });

    test('standard sizes are inserted in XS→2XL order', () {
      expect(sizeRowInsertIndex(const ['S', 'L'], 'M'), 1);
      expect(sizeRowInsertIndex(const ['M', 'L'], 'XS'), 0);
      expect(sizeRowInsertIndex(const ['S', 'M'], '2XL'), 2);
    });

    test('free size always sorts last', () {
      expect(sizeRowInsertIndex(const ['S', 'M'], '均碼'), 2);
      expect(sizeRowInsertIndex(const ['均碼'], 'M'), 0);
    });

    test('custom sizes sort after the standard sizes and before free size', () {
      expect(sizeRowInsertIndex(const ['S', 'M', '均碼'], '4XL'), 2);
      expect(sizeRowInsertIndex(const ['S', '2XL'], '4XL'), 2);
    });

    test('multiple custom sizes keep their insertion order', () {
      expect(sizeRowInsertIndex(const ['S', '4XL', '均碼'], '5XL'), 2);
      expect(sizeRowInsertIndex(const ['4XL', '5XL'], 'US 10'), 2);
    });

    test('XXL is a custom size and sorts after the standard sizes', () {
      expect(sizeRowInsertIndex(const ['S', 'M'], 'XXL'), 2);
      expect(sizeRowInsertIndex(const ['S', 'XXL', '均碼'], '4XL'), 2);
    });
  });
}
