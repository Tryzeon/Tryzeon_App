import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

/// Builds the plain-text order message sent to a store's DM channel.
class OrderMessageBuilder {
  const OrderMessageBuilder._();

  static String build({
    required final ShopProduct product,
    required final FitResult fitResult,
  }) {
    final lines = <String>[
      '【Tryzeon 試穿下單】',
      '商品：${product.name}',
      '尺寸：${_sizeLine(fitResult)}',
      '數量：1',
      AppConstants.productWebUrl(product.id),
    ];
    return lines.join('\n');
  }

  static String _sizeLine(final FitResult fitResult) {
    final size = fitResult.recommendedSize;
    if (fitResult.noUserData || size == null) return '（未提供）';
    return size;
  }
}
