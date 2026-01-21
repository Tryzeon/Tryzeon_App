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
  Future<Result<List<Product>, String>> getProducts({
    final bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
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
      }

      final models = await _remoteDataSource.fetchProducts();
      await _localDataSource.setCache(models);

      final products = models.map((final m) {
        return m.copyWith(imageUrl: _remoteDataSource.getProductImageUrl(m.imagePath));
      }).toList();

      return Ok(products);
    } catch (e) {
      AppLogger.error('無法載入商品列表', e);

      // Graceful degradation: 失敗時嘗試返回 cache
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

      return const Err('無法載入商品列表，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> createProduct({
    required final Product product,
    required final File image,
  }) async {
    try {
      final imagePath = await _remoteDataSource.uploadProductImage(image);

      // 同時保存到本地快取
      final bytes = await image.readAsBytes();
      await _localDataSource.saveProductImage(bytes, imagePath);

      final imageUrl = _remoteDataSource.getProductImageUrl(imagePath);

      final productModel = ProductModel(
        storeId: product.storeId,
        name: product.name,
        types: product.types,
        price: product.price,
        imagePath: imagePath,
        imageUrl: imageUrl,
        purchaseLink: product.purchaseLink,
      );

      final productId = await _remoteDataSource.insertProduct(productModel);

      final sizes = product.sizes ?? [];
      if (sizes.isNotEmpty) {
        final sizeModels = sizes.map((final size) {
          return ProductSizeModel(
            productId: productId,
            name: size.name,
            measurements: size.measurements,
          );
        }).toList();
        await _remoteDataSource.insertProductSizes(sizeModels);
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

      final productChanged = original != finalTarget;
      final sizesChanged = original.sizes != target.sizes;

      if (!productChanged && !sizesChanged && newImage == null) {
        return const Ok(null);
      }

      if (productChanged) {
        await _remoteDataSource.updateProduct(ProductModel.fromEntity(finalTarget));
      }

      if (newImage != null) {
        _remoteDataSource.deleteProductImage(original.imagePath).ignore();
        _localDataSource.deleteProductImage(original.imagePath).ignore();
      }

      if (sizesChanged) {
        final originalSizes = original.sizes ?? [];
        final targetSizes = target.sizes ?? [];

        final targetSizeIds = targetSizes
            .map((final s) => s.id)
            .whereType<String>()
            .toSet();

        // Delete removed sizes
        for (final originalSize in originalSizes) {
          if (originalSize.id != null && !targetSizeIds.contains(originalSize.id)) {
            await _remoteDataSource.deleteProductSize(originalSize.id!);
          }
        }

        // Add new sizes
        for (final targetSize in targetSizes) {
          if (targetSize.id == null) {
            await _remoteDataSource.insertProductSize(
              ProductSizeModel(
                productId: original.id,
                name: targetSize.name,
                measurements: targetSize.measurements,
              ),
            );
          } else {
            // Update existing sizes if changed
            final originalSize = originalSizes.cast<ProductSize?>().firstWhere(
              (final s) => s?.id == targetSize.id,
              orElse: () => null,
            );

            if (originalSize != null && originalSize != targetSize) {
              await _remoteDataSource.updateProductSize(
                ProductSizeModel.fromEntity(targetSize),
              );
            }
          }
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
