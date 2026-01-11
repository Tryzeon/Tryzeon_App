import 'package:tryzeon/feature/common/product_type/domain/entities/product_type.dart';

class ProductTypeLocalDataSource {
  List<ProductType>? _cached;

  List<ProductType>? getCached() => _cached;

  void cache(final List<ProductType> types) {
    _cached = types;
  }
}
