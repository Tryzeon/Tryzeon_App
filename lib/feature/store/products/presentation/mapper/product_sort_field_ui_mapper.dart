import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

/// UI label extension for [SortField] in Presentation Layer.
extension SortFieldLabel on SortField {
  String get label => switch (this) {
    SortField.name => '名稱',
    SortField.price => '價格',
    SortField.createdAt => '建立時間',
    SortField.updatedAt => '更新時間',
    SortField.tryonCount => '試穿次數',
    SortField.purchaseClickCount => '購買點擊次數',
  };
}
