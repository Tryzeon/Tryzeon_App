import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/account/presentation/state/unlist_reminder.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

Product product(final String name, {final ProductStatus status = ProductStatus.active}) {
  final now = DateTime(2026, 8, 18);
  return Product(
    id: name,
    storeId: 's1',
    name: name,
    categoryId: 'c1',
    price: 100,
    imagePaths: const [],
    imageUrls: const [],
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('只留下有購買點擊的商品', () {
    final reminders = selectUnlistReminders(
      [product('白襯衫'), product('黑褲')],
      const {'白襯衫': 3},
    );

    expect(reminders.map((final r) => r.product.name), ['白襯衫']);
    expect(reminders.single.clicks, 3);
  });

  test('已下架的商品不再提醒下架', () {
    final reminders = selectUnlistReminders(
      [product('黑褲', status: ProductStatus.archived)],
      const {'黑褲': 9},
    );

    expect(reminders, isEmpty);
  });

  test('照購買點擊數由高到低排序', () {
    final reminders = selectUnlistReminders(
      [product('白襯衫'), product('黑褲'), product('外套')],
      const {'白襯衫': 2, '黑褲': 11, '外套': 7},
    );

    expect(reminders.map((final r) => r.product.name), ['黑褲', '外套', '白襯衫']);
  });

  test('不改動傳入的商品清單', () {
    final products = [product('白襯衫'), product('黑褲')];

    selectUnlistReminders(products, const {'白襯衫': 1, '黑褲': 5});

    expect(products.map((final p) => p.name), ['白襯衫', '黑褲']);
  });
}
