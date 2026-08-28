import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';

void main() {
  test('toggled 兩個方向都會回到原狀態', () {
    for (final status in ProductStatus.values) {
      expect(status.toggled.toggled, status);
      expect(status.toggled, isNot(status));
    }
  });

  // The label says what leaving this state is called, the message says what
  // arriving in one is called — reading either off the wrong status is the
  // mistake this locks down: unlisting must not announce 已重新上架.
  test('動作文案讀舊狀態，結果文案讀新狀態', () {
    expect(ProductStatus.active.toggleLabel, '下架商品');
    expect(ProductStatus.active.toggled.arrivedMessage, contains('已下架'));

    expect(ProductStatus.archived.toggleLabel, '重新上架');
    expect(ProductStatus.archived.toggled.arrivedMessage, '已重新上架');
  });
}
