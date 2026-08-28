import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';

typedef AnalyticsLookup = int Function(String productId, AnalyticsMetric metric);

Comparator<Product> buildProductComparator(
  final SortKey key,
  final bool ascending,
  final AnalyticsLookup lookup,
) {
  final primary = switch (key) {
    ProductSortKey(:final field) => _byProductField(field),
    AnalyticsSortKey(:final metric) => (final Product a, final Product b) => lookup(
      a.id,
      metric,
    ).compareTo(lookup(b.id, metric)),
  };
  return (final a, final b) {
    final r = ascending ? primary(a, b) : -primary(a, b);
    if (r != 0) return r;
    return b.createdAt.compareTo(a.createdAt);
  };
}

Comparator<Product> _byProductField(final ProductField field) => switch (field) {
  ProductField.name => (final a, final b) => a.name.compareTo(b.name),
  ProductField.price => (final a, final b) => a.price.compareTo(b.price),
  ProductField.createdAt => (final a, final b) => a.createdAt.compareTo(b.createdAt),
  ProductField.updatedAt => (final a, final b) => a.updatedAt.compareTo(b.updatedAt),
};
