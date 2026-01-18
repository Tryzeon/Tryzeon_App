import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_type/data/datasources/product_type_local_datasource.dart';
import 'package:tryzeon/feature/common/product_type/data/datasources/product_type_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_type/domain/entities/product_type.dart';
import 'package:tryzeon/feature/common/product_type/domain/repositories/product_type_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductTypeRepositoryImpl implements ProductTypeRepository {
  ProductTypeRepositoryImpl(this._remote, this._local);
  final ProductTypeRemoteDataSource _remote;
  final ProductTypeLocalDataSource _local;

  @override
  Future<Result<List<ProductType>, String>> getProductTypes() async {
    try {
      final cached = await _local.getCached();
      if (cached != null && cached.isNotEmpty) {
        return Ok(cached);
      }
      final remote = await _remote.fetchProductTypes();
      await _local.cache(remote);
      return Ok(remote);
    } catch (e) {
      AppLogger.error('商品類型獲取失敗', e);
      return const Err('無法載入商品類型，請檢查網路連線');
    }
  }
}
