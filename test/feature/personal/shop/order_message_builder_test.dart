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
  // 連結必須自成一行且不帶前綴：LINE / Messenger 的 linkifier 才抓得到整串網址，
  // 抓不到就沒有預覽卡 —— 加這行的唯一理由就是預覽卡。
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
