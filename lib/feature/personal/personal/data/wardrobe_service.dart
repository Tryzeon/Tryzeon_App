import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _wardrobeTable = 'wardrobe_items';
  static const _bucket = 'wardrobe';

  static const _cacheKey = 'wardrobe_items_cache';

  static Future<Result<List<Clothing>>> getClothing({
    final bool forceRefresh = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure('請重新登入');
    }

    try {
      // 如果不是強制刷新，先嘗試從快取讀取
      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          final clothing = cachedData
              .map((final json) => Clothing.fromJson(json))
              .toList();
          return Result.success(data: clothing);
        }
      }

      // 從資料庫獲取資料
      final response = await _supabase
          .from(_wardrobeTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      await CacheService.saveList(_cacheKey, response);

      final clothing = (response as List)
          .map((final json) => Clothing.fromJson(json))
          .toList();

      return Result.success(data: clothing);
    } catch (e) {
      return Result.failure('獲取衣櫃列表失敗', error: e);
    }
  }

  static Future<Result<List<Clothing>>> uploadClothing(
    final File imageFile,
    final String category, {
    final List<String> tags = const [],
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure('請重新登入');
    }

    final categoryCode = getWardrobeTypesEnglishCode(category);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$categoryCode/$timestamp.jpg';

    try {
      // 1. 上傳圖片到 Supabase Storage
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // 2. 保存到本地緩存
      await CacheService.saveImage(bytes, storagePath);

      // 3. 新增 DB 記錄
      await _supabase.from(_wardrobeTable).insert({
        'user_id': userId,
        'category': category,
        'image_path': storagePath,
        'tags': tags,
      });

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('上傳衣物失敗', error: e);
    }
  }

  static Future<Result<List<Clothing>>> deleteClothing(
    final Clothing item,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure('請重新登入');
    }

    try {
      // 1. 刪除 DB 記錄
      await _supabase.from(_wardrobeTable).delete().eq('id', item.id!);

      // 2. 刪除 Supabase Storage 中的圖片
      await _supabase.storage.from(_bucket).remove([item.imagePath]);

      // 3. 刪除本地快取的圖片
      await CacheService.deleteImage(item.imagePath);

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('刪除衣物失敗', error: e);
    }
  }

  static Future<Result<File>> loadClothingImage(
    final String storagePath,
  ) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedFile = await CacheService.getImage(storagePath);
      if (cachedFile != null && await cachedFile.exists()) {
        return Result.success(file: cachedFile);
      }

      // 2. 本地沒有，從 Supabase 下載並保存到本地緩存
      final bytes = await _supabase.storage.from(_bucket).download(storagePath);
      final savedFile = await CacheService.saveImage(bytes, storagePath);

      return Result.success(file: savedFile);
    } catch (e) {
      return Result.failure('載入衣櫃圖片失敗', error: e);
    }
  }

  static List<String> getWardrobeTypesList() {
    return ClothingType.all.map((final t) => t.zh).toList();
  }

  static String getWardrobeTypesEnglishCode(final String nameZh) {
    final type = ClothingType.all
        .where((final t) => t.zh == nameZh)
        .firstOrNull;
    return type?.en ?? nameZh;
  }
}

class ClothingType {
  const ClothingType({required this.zh, required this.en});
  final String zh;
  final String en;

  static const List<ClothingType> all = [
    ClothingType(zh: '上衣', en: 'top'),
    ClothingType(zh: '褲子', en: 'pants'),
    ClothingType(zh: '裙子', en: 'skirt'),
    ClothingType(zh: '外套', en: 'jacket'),
    ClothingType(zh: '鞋子', en: 'shoes'),
    ClothingType(zh: '配件', en: 'accessories'),
    ClothingType(zh: '其他', en: 'others'),
  ];
}

class Clothing {
  Clothing({
    this.id,
    required this.imagePath,
    required this.category,
    this.tags = const [],
  });

  factory Clothing.fromJson(final Map<String, dynamic> json) {
    return Clothing(
      id: json['id'],
      imagePath: json['image_path'],
      category: json['category'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
    );
  }

  final String? id;
  final String imagePath;
  final String category;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'category': category,
      'tags': tags,
    };
  }

  // 按需載入圖片，使用快取機制
  Future<Result<File>> loadImage() async {
    return WardrobeService.loadClothingImage(imagePath);
  }
}
