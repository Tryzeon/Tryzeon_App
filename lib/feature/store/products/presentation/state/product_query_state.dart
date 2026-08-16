import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_sorting.dart';

part 'product_query_state.freezed.dart';

@freezed
sealed class ProductQueryState with _$ProductQueryState {
  const factory ProductQueryState({
    @Default('') final String searchQuery,
    @Default(SortCondition.defaultSort) final SortCondition sort,
    @Default(ProductStatus.active) final ProductStatus status,
  }) = _ProductQueryState;
}

List<Product> filterAndSortProducts(
  final List<Product> products,
  final ProductQueryState query,
  final AnalyticsLookup analyticsLookup,
) {
  final normalizedSearchQuery = query.searchQuery.trim().toLowerCase();

  final filtered = products
      .where(
        (final product) =>
            product.status == query.status &&
            (normalizedSearchQuery.isEmpty ||
                product.name.toLowerCase().contains(normalizedSearchQuery)),
      )
      .toList();

  filtered.sort(
    buildProductComparator(query.sort.key, query.sort.ascending, analyticsLookup),
  );

  return filtered;
}
