import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_query_state.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';

Product product(
  final String name, {
  final ProductStatus status = ProductStatus.active,
}) {
  final now = DateTime(2026, 8, 16);
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

int noAnalytics(final String productId, final AnalyticsMetric metric) => 0;

void main() {
  test('returns only the products in the current tab status', () {
    final products = [
      product('White Shirt'),
      product('Black Pants', status: ProductStatus.archived),
    ];

    final active = filterAndSortProducts(
      products,
      const ProductQueryState(),
      noAnalytics,
    );
    expect(active.map((final p) => p.name), ['White Shirt']);

    final archived = filterAndSortProducts(
      products,
      const ProductQueryState(status: ProductStatus.archived),
      noAnalytics,
    );
    expect(archived.map((final p) => p.name), ['Black Pants']);
  });

  test('search applies within a status, not across statuses', () {
    // The bucket is the outer filter: a matching name in the other bucket must
    // stay out, or switching tabs would look like the search stopped working.
    final products = [
      product('Linen Shirt'),
      product('Linen Dress', status: ProductStatus.archived),
    ];

    final result = filterAndSortProducts(
      products,
      const ProductQueryState(searchQuery: 'linen'),
      noAnalytics,
    );

    expect(result.map((final p) => p.name), ['Linen Shirt']);
  });
}
