import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_sort_condition.freezed.dart';

enum ProductField { name, price, createdAt, updatedAt }

enum AnalyticsMetric { viewCount, tryonCount, purchaseClickCount }

@freezed
sealed class SortKey with _$SortKey {
  const factory SortKey.product(final ProductField field) = ProductSortKey;
  const factory SortKey.analytics(final AnalyticsMetric metric) = AnalyticsSortKey;
}

@freezed
sealed class SortCondition with _$SortCondition {
  const factory SortCondition({
    required final SortKey key,
    required final bool ascending,
  }) = _SortCondition;
  const SortCondition._();

  static const defaultSort = SortCondition(
    key: SortKey.product(ProductField.createdAt),
    ascending: false,
  );
}
