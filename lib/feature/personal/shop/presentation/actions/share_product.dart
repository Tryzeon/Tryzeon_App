import 'package:share_plus/share_plus.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

Future<void> shareProduct(final ShopProduct product) {
  return SharePlus.instance.share(
    ShareParams(text: AppConstants.productWebUrl(product.id)),
  );
}
