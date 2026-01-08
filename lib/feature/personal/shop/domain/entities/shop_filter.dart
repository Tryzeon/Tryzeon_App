import 'package:flutter/foundation.dart';

class ShopFilter {
  const ShopFilter({
    this.searchQuery,
    this.sortBy = 'created_at',
    this.ascending = false,
    this.minPrice,
    this.maxPrice,
    this.types,
  });

  final String? searchQuery;
  final String sortBy;
  final bool ascending;
  final int? minPrice;
  final int? maxPrice;
  final Set<String>? types;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is ShopFilter &&
        other.searchQuery == searchQuery &&
        other.sortBy == sortBy &&
        other.ascending == ascending &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        setEquals(other.types, types);
  }

  @override
  int get hashCode {
    return searchQuery.hashCode ^
        sortBy.hashCode ^
        ascending.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        Object.hashAll(types ?? {});
  }
}
