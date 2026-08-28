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
  test('只回傳目前分頁狀態的商品', () {
    final products = [
      product('白襯衫'),
      product('黑褲', status: ProductStatus.archived),
    ];

    final active = filterAndSortProducts(
      products,
      const ProductQueryState(),
      noAnalytics,
    );
    expect(active.map((final p) => p.name), ['白襯衫']);

    final archived = filterAndSortProducts(
      products,
      const ProductQueryState(status: ProductStatus.archived),
      noAnalytics,
    );
    expect(archived.map((final p) => p.name), ['黑褲']);
  });

  test('搜尋在狀態之內生效，不會撈到另一個狀態的同名商品', () {
    // The bucket is the outer filter: a matching name in the other bucket must
    // stay out, or switching tabs would look like the search stopped working.
    final products = [
      product('亞麻襯衫'),
      product('亞麻洋裝', status: ProductStatus.archived),
    ];

    final result = filterAndSortProducts(
      products,
      const ProductQueryState(searchQuery: '亞麻'),
      noAnalytics,
    );

    expect(result.map((final p) => p.name), ['亞麻襯衫']);
  });
}
