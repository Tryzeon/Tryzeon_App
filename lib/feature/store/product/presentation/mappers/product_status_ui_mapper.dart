import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

/// Store-facing wording for a product's listing state. 上架/下架 is what every
/// local marketplace already calls this, so it needs no explaining; 封存 and
/// 停用 both read as something heavier than it is.
extension ProductStatusUi on ProductStatus {
  String get tabLabel => switch (this) {
    ProductStatus.active => '上架中',
    ProductStatus.archived => '已下架',
  };

  /// What the action moving a product *out of* this state is called.
  String get toggleLabel => switch (this) {
    ProductStatus.active => '下架商品',
    // 重新, not a bare 上架 — next to the 已下架 label it has to read as
    // "put it back", not as a state the product is already in.
    ProductStatus.archived => '重新上架',
  };

  /// Confirmation for having *arrived* in this state — read it off the new
  /// status, not the old one.
  String get arrivedMessage => switch (this) {
    ProductStatus.active => '已重新上架',
    ProductStatus.archived => '已下架，顧客不會看到',
  };

  ProductStatus get toggled => switch (this) {
    ProductStatus.active => ProductStatus.archived,
    ProductStatus.archived => ProductStatus.active,
  };
}
