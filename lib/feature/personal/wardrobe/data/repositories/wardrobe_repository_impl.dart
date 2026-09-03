import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:typed_result/typed_result.dart';

import '../../domain/entities/wardrobe_item.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../datasources/wardrobe_local_datasource.dart';
import '../datasources/wardrobe_remote_datasource.dart';
import '../models/create_wardrobe_item_request.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({
    required final WardrobeRemoteDataSource remoteDataSource,
    required final WardrobeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final WardrobeRemoteDataSource _remoteDataSource;
  final WardrobeLocalDataSource _localDataSource;
  static const _mappr = PersonalMappr();

  @override
  Future<Result<List<WardrobeItem>, Failure>> getWardrobeItems({
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedItems = await _localDataSource.getWardrobeItems();
          switch (cachedItems) {
            case CacheHit<List<WardrobeItemModel>>(:final data):
              final items = _mappr.convertList<WardrobeItemModel, WardrobeItem>(data);
              return Ok(items);
            case CacheEmpty<List<WardrobeItemModel>>():
              return const Ok([]);
            case CacheMiss<List<WardrobeItemModel>>():
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
      final remoteItems = await _remoteDataSource.getWardrobeItems();

      // 3. Update Cache
      try {
        await _localDataSource.saveWardrobeItems(remoteItems);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save wardrobe items to cache', e, stackTrace);
      }

      final items = _mappr.convertList<WardrobeItemModel, WardrobeItem>(remoteItems);
      return Ok(items);
    } catch (e, stackTrace) {
      AppLogger.error('Wardrobe fetch failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> uploadWardrobeItem(
    final CreateWardrobeItemParams params,
  ) async {
    try {
      final categoryString = params.category.value;
      final imageName = p.basename(params.image.path);
      final bytes = await params.image.readAsBytes();

      // 1. Upload Image first
      final imagePath = await _remoteDataSource.uploadImage(
        category: categoryString,
        fileName: imageName,
        bytes: bytes,
      );

      await _localDataSource.saveImage(bytes, imagePath);

      // 2. Create Request DTO
      final request = CreateWardrobeItemRequest(
        imagePath: imagePath,
        category: params.category,
        tags: params.tags,
      );

      final newItem = await _remoteDataSource.createWardrobeItem(request);

      await _localDataSource.saveWardrobeItem(newItem);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload wardrobe item', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteWardrobeItem(final WardrobeItem item) async {
    try {
      await _remoteDataSource.deleteWardrobeItem(item.id);
      _remoteDataSource.deleteImage(item.imagePath).ignore();
      _localDataSource.deleteImage(item.imagePath).ignore();
      await _localDataSource.deleteWardrobeItem(item.id);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete wardrobe item', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WardrobeItem, Failure>> updateWardrobeItemTags({
    required final WardrobeItem item,
    required final List<String> tags,
  }) async {
    try {
      final updatedModel = await _remoteDataSource.updateWardrobeItemTags(
        id: item.id,
        tags: tags,
      );
      await _localDataSource.saveWardrobeItem(updatedModel);
      final updatedItem = _mappr.convert<WardrobeItemModel, WardrobeItem>(updatedModel);
      return Ok(updatedItem);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update wardrobe item tags', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<File, Failure>> getWardrobeItemImage(final String imagePath) async {
    try {
      final cachedImage = await _localDataSource.getImage(imagePath);
      if (cachedImage != null) return Ok(cachedImage);

      final url = await _remoteDataSource.createSignedUrl(imagePath);
      final image = await _localDataSource.getImage(imagePath, downloadUrl: url);

      if (image == null) {
        return const Err(UnknownFailure('Failed to retrieve wardrobe image'));
      }

      return Ok(image);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load wardrobe images', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
