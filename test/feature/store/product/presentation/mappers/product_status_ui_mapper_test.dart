import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';

void main() {
  test('toggled in either direction returns to the original status', () {
    for (final status in ProductStatus.values) {
      expect(status.toggled.toggled, status);
      expect(status.toggled, isNot(status));
    }
  });

  // The label says what leaving this state is called, the message says what
  // arriving in one is called — reading either off the wrong status is the
  // mistake this locks down: unlisting must not announce 已重新上架.
  test('the action label reads the old status and the result message the new one', () {
    expect(ProductStatus.active.toggleLabel, '下架商品');
    expect(ProductStatus.active.toggled.arrivedMessage, contains('已下架'));

    expect(ProductStatus.archived.toggleLabel, '重新上架');
    expect(ProductStatus.archived.toggled.arrivedMessage, '已重新上架');
  });
}
