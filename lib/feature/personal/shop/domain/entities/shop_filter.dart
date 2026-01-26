import 'package:equatable/equatable.dart';
import 'package:tryzeon/core/domain/entities/user_location.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';

class ShopFilter extends Equatable {
  const ShopFilter({
    this.searchQuery,
    this.sortOption = ProductSortOption.latest,
    this.minPrice,
    this.maxPrice,
    this.types,
    this.userLocation,
  });

  final String? searchQuery;
  final ProductSortOption sortOption;
  final int? minPrice;
  final int? maxPrice;
  final Set<String>? types;

  /// 使用者位置（用於附近店家排序）
  final UserLocation? userLocation;

  @override
  List<Object?> get props => [
    searchQuery,
    sortOption,
    minPrice,
    maxPrice,
    types,
    userLocation,
  ];
}
