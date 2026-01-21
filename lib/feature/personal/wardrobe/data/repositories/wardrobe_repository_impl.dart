import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';
import '../../domain/entities/wardrobe_category.dart';
import '../../domain/entities/wardrobe_item.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../datasources/wardrobe_local_datasource.dart';
import '../datasources/wardrobe_remote_datasource.dart';
import '../mappers/category_mapper.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({
    required final WardrobeRemoteDataSource remoteDataSource,
    required final WardrobeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final WardrobeRemoteDataSource _remoteDataSource;
  final WardrobeLocalDataSource _localDataSource;

  @override
  Future<Result<List<WardrobeItem>, String>> getWardrobeItems({
    final bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _localDataSource.getCachedItems();
        if (cached != null) return Ok(cached);
      }

      final items = await _remoteDataSource.fetchWardrobeItems();
      await _localDataSource.updateCachedItems(items);
      return Ok(items);
    } catch (e) {
      AppLogger.error('衣櫃列表獲取失敗', e);

      // Graceful degradation: 失敗時嘗試返回 cache
      final cached = await _localDataSource.getCachedItems();
      if (cached != null) return Ok(cached);

      return const Err('無法載入衣櫃列表，請檢查網路連線');
    }
  }

  @override
  Future<Result<void, String>> uploadWardrobeItem({
    required final File image,
    required final WardrobeCategory category,
    final List<String> tags = const [],
  }) async {
    try {
      // Convert category enum to string for API
      final categoryString = CategoryMapper.toApiString(category);
      final imageName = p.basename(image.path);
      final bytes = await image.readAsBytes();

      // 1. Upload Image first
      final imagePath = await _remoteDataSource.uploadImage(
        category: categoryString,
        fileName: imageName,
        bytes: bytes,
      );

      await _localDataSource.saveImage(bytes, imagePath);

      // 2. Create Item Model
      final newItemModel = WardrobeItemModel(
        imagePath: imagePath,
        category: category,
        tags: tags,
      );

      final newItem = await _remoteDataSource.createWardrobeItem(newItemModel);

      await _localDataSource.addItemToCache(newItem);

      return const Ok(null);
    } catch (e) {
      AppLogger.error('衣物上傳失敗', e);
      return const Err('上傳衣物失敗，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> deleteWardrobeItem(final WardrobeItem item) async {
    try {
      if (item.id == null) return const Err('無效的衣物 ID');

      await _remoteDataSource.deleteWardrobeItem(item.id!);
      _remoteDataSource.deleteImage(item.imagePath).ignore();
      _localDataSource.deleteImage(item.imagePath).ignore();
      await _localDataSource.removeItemFromCache(item.id!);

      return const Ok(null);
    } catch (e) {
      AppLogger.error('衣物刪除失敗', e);
      return const Err('刪除衣物失敗，請稍後再試');
    }
  }

  @override
  Future<Result<File, String>> getWardrobeItemImage(final String imagePath) async {
    try {
      final cachedImage = await _localDataSource.getImage(imagePath);
      if (cachedImage != null) return Ok(cachedImage);

      final url = await _remoteDataSource.createSignedUrl(imagePath);
      final image = await _localDataSource.getImage(imagePath, downloadUrl: url);

      if (image == null) return const Err('無法獲取衣物圖片，請稍後再試');

      return Ok(image);
    } catch (e) {
      AppLogger.error('衣櫃圖片載入失敗', e);
      return const Err('無法載入衣物圖片，請稍後再試');
    }
  }
}
