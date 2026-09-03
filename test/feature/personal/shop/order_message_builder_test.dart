import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/order_message_builder.dart';

ShopProduct product({required final List<String> imageUrls}) => ShopProduct(
  storeInfo: const ShopStoreInfo(id: 's1', name: '店', channels: {}),
  name: '白T',
  categoryId: 'c1',
  price: 590,
  imagePaths: const [],
  imageUrls: imageUrls,
  id: 'p1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // The link has to sit on its own line with no prefix so LINE's and Messenger's
  // linkifiers pick up the whole URL; without that there is no preview card, and
  // the preview card is the only reason this line exists.
  test('ends with the product web url on its own line', () {
    final message = OrderMessageBuilder.build(
      product: product(imageUrls: const ['https://img/a.jpg']),
      fitResult: const FitResult(recommendedSize: 'M'),
    );
    expect(message.split('\n').last, 'https://tryzeon.com/product/p1');
  });

  test('includes the link even when the product has no images', () {
    final message = OrderMessageBuilder.build(
      product: product(imageUrls: const []),
      fitResult: const FitResult(recommendedSize: 'M'),
    );
    expect(message.split('\n').last, 'https://tryzeon.com/product/p1');
  });
}
