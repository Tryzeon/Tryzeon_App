/// Public API of the shop feature.
///
/// Other features depend on this barrel — never on `shop/data/**` internals.
/// Exposes the domain entity plus the row decoder for consumers (e.g. chat)
/// that receive raw `list_shop_products` rows and need to render product cards.
library;

export 'data/models/product_row_mapper.dart' show decodeShopProductRow;
export 'domain/entities/shop_product.dart';
