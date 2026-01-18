import 'dart:io';

import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required final ProductRemoteDataSource remoteDataSource,
    required final ProductLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  @override
  Future<Result<List<Product>, String>> getProducts() async {
    try {
      final cached = await _localDataSource.getCache();
      if (cached != null) {
        return Ok(
          cached.map((final m) {
            return m.copyWith(
              imageUrl: _remoteDataSource.getProductImageUrl(m.imagePath),
            );
          }).toList(),
        );
      }

      final models = await _remoteDataSource.fetchProducts();
      await _localDataSource.setCache(models);

      final products = models.map((final m) {
        return m.copyWith(imageUrl: _remoteDataSource.getProductImageUrl(m.imagePath));
      }).toList();

      return Ok(products);
    } catch (e) {
      AppLogger.error('無法載入商品列表', e);
      return const Err('無法載入商品列表，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> createProduct({
    required final Product product,
    required final File image,
  }) async {
    try {
      final storeId = await _remoteDataSource.getStoreId();
      final imagePath = await _remoteDataSource.uploadProductImage(image);

      // 同時保存到本地快取
      final bytes = await image.readAsBytes();
      await _localDataSource.saveProductImage(bytes, imagePath);

      final imageUrl = _remoteDataSource.getProductImageUrl(imagePath);

      final productData = ProductModel(
        storeId: storeId,
        name: product.name,
        types: product.types,
        price: product.price,
        imagePath: imagePath,
        imageUrl: imageUrl,
        purchaseLink: product.purchaseLink,
      ).toJson();

      final productId = await _remoteDataSource.insertProduct(productData);

      final sizes = product.sizes ?? [];
      if (sizes.isNotEmpty) {
        final sizesData = sizes.map((final size) {
          return {
            'product_id': productId,
            'name': size.name,
            ...size.measurements.toJson(),
          };
        }).toList();
        await _remoteDataSource.insertProductSizes(sizesData);
      }

      final model = await _remoteDataSource.fetchProduct(productId);

      final currentCache = await _localDataSource.getCache() ?? [];
      await _localDataSource.setCache([model, ...currentCache]);

      return const Ok(null);
    } catch (e) {
      AppLogger.error('商品創建失敗', e);
      return const Err('新增商品失敗，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> updateProduct({
    required final Product original,
    required final Product target,
    final File? newImage,
  }) async {
    try {
      Product finalTarget = target;
      if (newImage != null) {
        final newImagePath = await _remoteDataSource.uploadProductImage(newImage);
        finalTarget = target.copyWith(imagePath: newImagePath);

        // 同時保存到本地快取
        final bytes = await newImage.readAsBytes();
        await _localDataSource.saveProductImage(bytes, newImagePath);
      }

      final updateData = original.getDirtyFields(finalTarget);
      final sizeChanges = original.sizes.getDirtyFields(target.sizes);

      if (updateData.isEmpty && !sizeChanges.hasChanges) {
        return const Ok(null);
      }

      if (updateData.isNotEmpty) {
        await _remoteDataSource.updateProduct(original.id!, updateData);
      }

      if (newImage != null) {
        _remoteDataSource.deleteProductImage(original.imagePath).ignore();
        _localDataSource.deleteProductImage(original.imagePath).ignore();
      }

      if (sizeChanges.hasChanges) {
        for (final id in sizeChanges.toDeleteIds) {
          await _remoteDataSource.deleteProductSize(id);
        }

        for (final newSize in sizeChanges.toAdd) {
          await _remoteDataSource.insertProductSize({
            'product_id': original.id,
            'name': newSize.name,
            ...newSize.measurements.toJson(),
          });
        }

        for (final updateEntry in sizeChanges.toUpdate) {
          final id = updateEntry['id'] as String;
          final dirtyFields = updateEntry['dirtyFields'] as Map<String, dynamic>;
          await _remoteDataSource.updateProductSize(id, dirtyFields);
        }
      }

      final model = await _remoteDataSource.fetchProduct(original.id!);

      final currentCache = await _localDataSource.getCache() ?? [];
      await _localDataSource.setCache(
        currentCache.map((final p) => p.id == model.id ? model : p).toList(),
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('商品更新失敗', e);
      return const Err('更新商品失敗，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> deleteProduct(final Product product) async {
    try {
      await _remoteDataSource.deleteProduct(product.id!);
      await _remoteDataSource.deleteProductSizes(product.id!);

      if (product.imagePath.isNotEmpty) {
        _remoteDataSource.deleteProductImage(product.imagePath).ignore();
        _localDataSource.deleteProductImage(product.imagePath).ignore();
      }

      final currentCache = await _localDataSource.getCache() ?? [];
      await _localDataSource.setCache(
        currentCache.where((final p) => p.id != product.id).toList(),
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('商品刪除失敗', e);
      return const Err('刪除商品失敗，請稍後再試');
    }
  }
}
