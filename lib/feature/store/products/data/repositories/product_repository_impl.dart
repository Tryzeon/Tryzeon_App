import 'dart:io';

import 'package:tryzeon/core/data/utils/json_diff.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_request.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_size_request.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';
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

  /// Columns backed by a `Set` in the domain layer, whose list order therefore
  /// carries no meaning and must not read as a change.
  static const _productUnorderedKeys = {'category_ids', 'styles', 'seasons'};

  static GarmentMeasurementsModel? _toMeasurementsModel(
    final GarmentMeasurements? measurements,
  ) {
    if (measurements == null) return null;
    return const GarmentMeasurementsMappr()
        .convert<GarmentMeasurements, GarmentMeasurementsModel>(measurements);
  }

  static CreateProductSizeRequest _toSizeRequest(
    final String productId,
    final NewSizeItem size,
  ) {
    return CreateProductSizeRequest(
      productId: productId,
      name: size.name,
      measurements: _toMeasurementsModel(size.measurements),
    );
  }

  @override
  Future<Result<List<Product>, Failure>> listProducts({
    required final String storeId,
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedProducts = await _localDataSource.listProducts(storeId: storeId);
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
      final remoteProducts = await _remoteDataSource.listProducts(storeId: storeId);

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
      final draft = params.draft;

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
        name: draft.name,
        categoryIds: draft.categoryIds,
        price: draft.price,
        imagePaths: imagePaths,
        gender: draft.gender.value,
        purchaseLink: draft.purchaseLink,
        material: draft.material,
        elasticity: draft.elasticity?.value,
        fit: draft.fit,
        thickness: draft.thickness?.value,
        styles: draft.styles?.map((final e) => e.value).toList(),
        seasons: draft.seasons?.map((final e) => e.value).toList(),
      );

      await _remoteDataSource.insertProduct(request);

      if (params.sizes.isNotEmpty) {
        await _remoteDataSource.insertProductSizes(
          params.sizes.map((final size) => _toSizeRequest(productId, size)).toList(),
        );
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
  Future<Result<void, Failure>> updateProduct(final UpdateProductParams params) async {
    try {
      final original = params.original;
      final target = original.applyDraft(params.draft);
      final targetImages = params.images;
      final targetSizes = params.sizes;

      // 1. Separate existing paths and new files from final order
      final existingPaths = <String>[];
      final newFiles = <File>[];

      for (int i = 0; i < targetImages.length; i++) {
        final item = targetImages[i];
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

      for (final item in targetImages) {
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

      final targetProduct = target.copyWith(imagePaths: finalImagePaths);

      // 5. Diff against the original so an untouched column keeps whatever
      // value the server has — `original` is the snapshot the user edited.
      final productChanges = jsonDiff(
        _mappr.convert<Product, ProductModel>(original).toJson(),
        _mappr.convert<Product, ProductModel>(targetProduct).toJson(),
        unorderedKeys: _productUnorderedKeys,
      );
      final sizeDiff = computeSizeDiff(original.sizes, targetSizes);

      if (productChanges.isEmpty && sizeDiff.isEmpty) {
        return const Ok(null);
      }

      // 6. Update product in DB
      if (productChanges.isNotEmpty) {
        await _remoteDataSource.updateProduct(original.id, productChanges);
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
      for (final sizeId in sizeDiff.idsToDelete) {
        await _remoteDataSource.deleteProductSize(sizeId);
      }

      for (final size in sizeDiff.toAdd) {
        await _remoteDataSource.insertProductSize(_toSizeRequest(original.id, size));
      }

      for (final update in sizeDiff.toUpdate) {
        final targetSize = ProductSize(
          id: update.original.id,
          productId: update.original.productId,
          name: update.target.name,
          measurements: update.target.measurements,
          createdAt: update.original.createdAt,
          updatedAt: update.original.updatedAt,
        );
        final sizeChanges = jsonDiff(
          _mappr.convert<ProductSize, ProductSizeModel>(update.original).toJson(),
          _mappr.convert<ProductSize, ProductSizeModel>(targetSize).toJson(),
        );
        await _remoteDataSource.updateProductSize(update.original.id, sizeChanges);
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
