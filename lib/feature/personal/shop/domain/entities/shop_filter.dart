import 'package:equatable/equatable.dart';

class ShopFilter extends Equatable {
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
  List<Object?> get props => [searchQuery, sortBy, ascending, minPrice, maxPrice, types];
}
