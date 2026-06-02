import 'dart:io';

import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/measurements/data/mappers/measurements_mappr.dart';
import 'package:tryzeon/feature/common/measurements/data/models/measurements_model.dart';
import 'package:tryzeon/feature/common/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_request.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_size_request.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:typed_result/typed_result.dart';
import 'package:uuid/uuid.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required final ProductRemoteDataSource remoteDataSource,
    required final ProductLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  static const _mappr = StoreMappr();
  static const _uuid = Uuid();

  @override
  Future<Result<List<Product>, Failure>> getProducts({
    required final String storeId,
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedProducts = await _localDataSource.getProducts(storeId: storeId);
          switch (cachedProducts) {
            case CacheHit<List<ProductModel>>(:final data):
              return Ok(_mappr.convertList<ProductModel, Product>(data));
            case CacheEmpty<List<ProductModel>>():
              return const Ok([]);
            case CacheMiss<List<ProductModel>>():
              break;
          }
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Local cache read failed, falling back to remote',
            e,
            stackTrace,
          );
        }
      }

      // 2. Try Remote
      final remoteProducts = await _remoteDataSource.getProducts(storeId: storeId);

      // 3. Update Cache
      try {
        await _localDataSource.saveProducts(storeId, remoteProducts);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save products to cache', e, stackTrace);
      }

      final products = _mappr.convertList<ProductModel, Product>(remoteProducts);
      return Ok(products);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> createProduct(final CreateProductParams params) async {
    try {
      final productId = _uuid.v4();

      final imagePaths = await _remoteDataSource.uploadProductImages(
        storeId: params.storeId,
        productId: productId,
        images: params.images,
      );

      // Save to local cache
      for (int i = 0; i < params.images.length; i++) {
        final bytes = await params.images[i].readAsBytes();
        await _localDataSource.saveProductImage(bytes, imagePaths[i]);
      }

      final request = CreateProductRequest(
        id: productId,
        storeId: params.storeId,
        name: params.name,
        categoryIds: params.categoryIds,
        price: params.price,
        imagePaths: imagePaths,
        gender: params.gender.value,
        purchaseLink: params.purchaseLink,
        material: params.material,
        elasticity: params.elasticity?.value,
        fit: params.fit,
        thickness: params.thickness?.value,
        styles: params.styles?.map((final e) => e.value).toList(),
        seasons: params.seasons?.map((final e) => e.value).toList(),
      );

      await _remoteDataSource.insertProduct(request);

      final sizesList = params.sizes ?? [];
      if (sizesList.isNotEmpty) {
        final sizeRequests = sizesList
            .map(
              (final size) => CreateProductSizeRequest(
                productId: productId,
                name: size.name,
                measurements: size.measurements != null
                    ? const MeasurementsMappr().convert<Measurements, MeasurementsModel>(
                        size.measurements!,
                      )
                    : null,
              ),
            )
            .toList();
        await _remoteDataSource.insertProductSizes(sizeRequests);
      }

      final model = await _remoteDataSource.getProduct(productId);
      await _localDataSource.saveProduct(model);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Fail to create product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Product, Failure>> getProductById(final String productId) async {
    try {
      // 1. Try Local Cache
      try {
        final cachedProduct = await _localDataSource.getProductById(productId);
        switch (cachedProduct) {
          case CacheHit<ProductModel>(:final data):
            return Ok(_mappr.convert<ProductModel, Product>(data));
          case CacheEmpty<ProductModel>():
          case CacheMiss<ProductModel>():
            break;
        }
      } catch (e, stackTrace) {
        AppLogger.warning('Local cache read failed', e, stackTrace);
      }

      // 2. Try Remote
      final model = await _remoteDataSource.getProduct(productId);

      // 3. Update Cache
      try {
        await _localDataSource.saveProduct(model);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save product to cache', e, stackTrace);
      }

      return Ok(_mappr.convert<ProductModel, Product>(model));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product by ID', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final UpdateProductParams params,
  }) async {
    try {
      // 1. Separate existing paths and new files from final order
      final existingPaths = <String>[];
      final newFiles = <File>[];

      for (int i = 0; i < params.finalImageOrder.length; i++) {
        final item = params.finalImageOrder[i];
        switch (item) {
          case ExistingImageItem(:final path):
            existingPaths.add(path);
          case NewImageItem(:final file):
            newFiles.add(file);
        }
      }

      // 2. Upload new images if any
      List<String> uploadedPaths = [];
      if (newFiles.isNotEmpty) {
        uploadedPaths = await _remoteDataSource.uploadProductImages(
          storeId: original.storeId,
          productId: original.id,
          images: newFiles,
        );

        // Save to local cache
        for (int i = 0; i < newFiles.length; i++) {
          final bytes = await newFiles[i].readAsBytes();
          await _localDataSource.saveProductImage(bytes, uploadedPaths[i]);
        }
      }

      // 3. Build final image paths in correct order
      final finalImagePaths = <String>[];
      int existingIndex = 0;
      int newIndex = 0;

      for (final item in params.finalImageOrder) {
        switch (item) {
          case ExistingImageItem():
            finalImagePaths.add(existingPaths[existingIndex++]);
          case NewImageItem():
            finalImagePaths.add(uploadedPaths[newIndex++]);
        }
      }

      // 4. Compute removed images via diff
      final removedPaths = original.imagePaths
          .where((final p) => !finalImagePaths.contains(p))
          .toList();

      // 5. Build target product
      final targetProduct = original.copyWith(
        name: params.name,
        categoryIds: params.categoryIds,
        price: params.price,
        gender: params.gender,
        purchaseLink: params.purchaseLink,
        material: params.material,
        elasticity: params.elasticity,
        fit: params.fit,
        thickness: params.thickness,
        styles: params.styles,
        seasons: params.seasons,
        imagePaths: finalImagePaths,
      );

      final productChanged = original != targetProduct;
      final sizesChanged =
          params.sizesToAdd.isNotEmpty ||
          params.sizesToUpdate.isNotEmpty ||
          params.sizeIdsToDelete.isNotEmpty;

      if (!productChanged && !sizesChanged) {
        return const Ok(null);
      }

      // 6. Update product in DB
      if (productChanged) {
        final targetModel = _mappr.convert<Product, ProductModel>(targetProduct);
        await _remoteDataSource.updateProduct(targetModel);
      }

      // 7. Drop removed images locally and on R2.
      if (removedPaths.isNotEmpty) {
        _localDataSource.deleteProductImages(removedPaths).ignore();
        _remoteDataSource
            .deleteProductImages(storeId: original.storeId, keys: removedPaths)
            .onError((final e, final s) {
              AppLogger.warning('R2 delete failed for removed images', e, s);
            });
      }

      // 8. Handle size changes
      if (sizesChanged) {
        // Delete removed sizes
        for (final sizeId in params.sizeIdsToDelete) {
          await _remoteDataSource.deleteProductSize(sizeId);
        }

        // Add new sizes
        for (final sizeParams in params.sizesToAdd) {
          final sizeRequest = CreateProductSizeRequest(
            productId: original.id,
            name: sizeParams.name,
            measurements: sizeParams.measurements != null
                ? const MeasurementsMappr().convert<Measurements, MeasurementsModel>(
                    sizeParams.measurements!,
                  )
                : null,
          );
          await _remoteDataSource.insertProductSize(sizeRequest);
        }

        // Update existing sizes
        for (final size in params.sizesToUpdate) {
          final sizeModel = _mappr.convert<ProductSize, ProductSizeModel>(size);
          await _remoteDataSource.updateProductSize(sizeModel);
        }
      }

      // 9. Update local cache
      final model = await _remoteDataSource.getProduct(original.id);
      await _localDataSource.saveProduct(model);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Fail to update product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteProduct(final Product product) async {
    try {
      await _remoteDataSource.deleteProduct(product.id);
      await _remoteDataSource.deleteProductSizes(product.id);

      if (product.imagePaths.isNotEmpty) {
        _localDataSource.deleteProductImages(product.imagePaths).ignore();
        _remoteDataSource
            .deleteProductImages(storeId: product.storeId, keys: product.imagePaths)
            .onError((final e, final s) {
              AppLogger.warning('R2 delete failed for product images', e, s);
            });
      }

      await _localDataSource.deleteProduct(
        storeId: product.storeId,
        productId: product.id,
      );

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Fail to delete product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
