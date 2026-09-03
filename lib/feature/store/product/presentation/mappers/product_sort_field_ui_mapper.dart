import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';

extension SortKeyLabels on SortKey {
  String get label => switch (this) {
    ProductSortKey(:final field) => switch (field) {
      ProductField.name => '名稱',
      ProductField.price => '價格',
      ProductField.createdAt => '建立時間',
      ProductField.updatedAt => '更新時間',
    },
    AnalyticsSortKey(:final metric) => switch (metric) {
      AnalyticsMetric.viewCount => '瀏覽次數',
      AnalyticsMetric.tryonCount => '試穿次數',
      AnalyticsMetric.purchaseClickCount => '購買點擊',
    },
  };

  String get ascendingLabel => switch (this) {
    ProductSortKey(:final field) => switch (field) {
      ProductField.name => 'A → Z',
      ProductField.price => '由低到高',
      ProductField.createdAt => '最舊 → 最新',
      ProductField.updatedAt => '最舊 → 最新',
    },
    AnalyticsSortKey() => '最少 → 最多',
  };

  String get descendingLabel => switch (this) {
    ProductSortKey(:final field) => switch (field) {
      ProductField.name => 'Z → A',
      ProductField.price => '由高到低',
      ProductField.createdAt => '最新 → 最舊',
      ProductField.updatedAt => '最新 → 最舊',
    },
    AnalyticsSortKey() => '最多 → 最少',
  };
}

/// Canonical ordering of sort options shown in the sort sheet.
const List<SortKey> allSortKeys = [
  SortKey.product(ProductField.createdAt),
  SortKey.product(ProductField.updatedAt),
  SortKey.product(ProductField.name),
  SortKey.product(ProductField.price),
  SortKey.analytics(AnalyticsMetric.viewCount),
  SortKey.analytics(AnalyticsMetric.tryonCount),
  SortKey.analytics(AnalyticsMetric.purchaseClickCount),
];
