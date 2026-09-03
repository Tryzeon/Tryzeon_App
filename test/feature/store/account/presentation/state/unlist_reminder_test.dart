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
  test('keeps only the products with purchase clicks', () {
    final reminders = selectUnlistReminders(
      [product('Shirt'), product('Pants')],
      const {'Shirt': 3},
    );

    expect(reminders.map((final r) => r.product.name), ['Shirt']);
    expect(reminders.single.clicks, 3);
  });

  test('an already unlisted product is not suggested for unlisting again', () {
    final reminders = selectUnlistReminders(
      [product('Pants', status: ProductStatus.archived)],
      const {'Pants': 9},
    );

    expect(reminders, isEmpty);
  });

  test('sorts by purchase clicks, highest first', () {
    final reminders = selectUnlistReminders(
      [product('Shirt'), product('Pants'), product('Jacket')],
      const {'Shirt': 2, 'Pants': 11, 'Jacket': 7},
    );

    expect(reminders.map((final r) => r.product.name), ['Pants', 'Jacket', 'Shirt']);
  });

  test('does not mutate the product list it was given', () {
    final products = [product('Shirt'), product('Pants')];

    selectUnlistReminders(products, const {'Shirt': 1, 'Pants': 5});

    expect(products.map((final p) => p.name), ['Shirt', 'Pants']);
  });
}
