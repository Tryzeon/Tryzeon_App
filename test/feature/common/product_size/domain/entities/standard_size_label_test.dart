import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';

void main() {
  group('StandardSizeLabel.tryParse', () {
    test('認得標準寫法（不分大小寫與空白）', () {
      expect(StandardSizeLabel.tryParse('M'), StandardSizeLabel.m);
      expect(StandardSizeLabel.tryParse(' m '), StandardSizeLabel.m);
      expect(StandardSizeLabel.tryParse('xl'), StandardSizeLabel.xl);
      expect(StandardSizeLabel.tryParse('2XL'), StandardSizeLabel.xxl);
    });

    test('不做別名轉換：XXL 是自訂尺碼，不等於 2XL', () {
      expect(StandardSizeLabel.tryParse('XXL'), isNull);
      expect(StandardSizeLabel.xxl.display, '2XL');
    });

    test('均碼只認字面值，F/free 一律是自訂尺碼', () {
      expect(StandardSizeLabel.tryParse('均碼'), StandardSizeLabel.free);
      expect(StandardSizeLabel.tryParse('F'), isNull);
      expect(StandardSizeLabel.tryParse('free'), isNull);
      expect(StandardSizeLabel.tryParse('One Size'), isNull);
    });

    test('認不出來的名稱回傳 null（代表自訂尺碼）', () {
      expect(StandardSizeLabel.tryParse('4XL'), isNull);
      expect(StandardSizeLabel.tryParse('US 10'), isNull);
      expect(StandardSizeLabel.tryParse(''), isNull);
    });
  });

  group('StandardSizeLabel.matchKeyOf', () {
    test('只去空白與大寫，大小寫不同視為同一個尺寸', () {
      expect(StandardSizeLabel.matchKeyOf(' m '), 'M');
      expect(StandardSizeLabel.matchKeyOf('us 10'), 'US 10');
    });

    test('別名不再收斂：XXL 與 2XL 是不同的 key', () {
      expect(
        StandardSizeLabel.matchKeyOf('XXL'),
        isNot(StandardSizeLabel.matchKeyOf('2XL')),
      );
    });
  });

  group('sizeRowInsertIndex', () {
    test('空清單插在最前面', () {
      expect(sizeRowInsertIndex(const [], 'M'), 0);
    });

    test('標準尺碼照 XS→2XL 的順序插入', () {
      expect(sizeRowInsertIndex(const ['S', 'L'], 'M'), 1);
      expect(sizeRowInsertIndex(const ['M', 'L'], 'XS'), 0);
      expect(sizeRowInsertIndex(const ['S', 'M'], '2XL'), 2);
    });

    test('均碼永遠排最後', () {
      expect(sizeRowInsertIndex(const ['S', 'M'], '均碼'), 2);
      expect(sizeRowInsertIndex(const ['均碼'], 'M'), 0);
    });

    test('自訂尺碼排在標準尺碼之後、均碼之前', () {
      expect(sizeRowInsertIndex(const ['S', 'M', '均碼'], '4XL'), 2);
      expect(sizeRowInsertIndex(const ['S', '2XL'], '4XL'), 2);
    });

    test('多個自訂尺碼保持新增順序', () {
      expect(sizeRowInsertIndex(const ['S', '4XL', '均碼'], '5XL'), 2);
      expect(sizeRowInsertIndex(const ['4XL', '5XL'], 'US 10'), 2);
    });

    test('XXL 是自訂尺碼，排在標準尺碼之後', () {
      expect(sizeRowInsertIndex(const ['S', 'M'], 'XXL'), 2);
      expect(sizeRowInsertIndex(const ['S', 'XXL', '均碼'], '4XL'), 2);
    });
  });
}
