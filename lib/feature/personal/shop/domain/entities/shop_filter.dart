import 'package:equatable/equatable.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';

class ShopFilter extends Equatable {
  const ShopFilter({
    this.searchQuery,
    this.sortOption = ProductSortOption.latest,
    this.minPrice,
    this.maxPrice,
    this.types,
  });

  final String? searchQuery;
  final ProductSortOption sortOption;
  final int? minPrice;
  final int? maxPrice;
  final Set<String>? types;

  @override
  List<Object?> get props => [searchQuery, sortOption, minPrice, maxPrice, types];
}
