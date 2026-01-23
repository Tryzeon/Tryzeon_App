import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

/// Database column mapper extension for [SortField] in Data Layer.
extension SortFieldDbMapper on SortField {
  /// Maps enum to database column name.
  String toDbColumn() {
    return switch (this) {
      SortField.name => 'name',
      SortField.price => 'price',
      SortField.createdAt => 'created_at',
      SortField.updatedAt => 'updated_at',
      SortField.tryonCount => 'tryon_count',
      SortField.purchaseClickCount => 'purchase_click_count',
    };
  }
}
