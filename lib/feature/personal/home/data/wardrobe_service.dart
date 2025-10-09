import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'wardrobe';

  static const _categories = {
    '上衣': 'top',
    '褲子': 'pants',
    '裙子': 'skirt',
    '外套': 'jacket',
    '鞋子': 'shoes',
    '配件': 'accessories',
    '其他': 'others',
  };

  static Future<Map<String, String>?> uploadWardrobeItem(File imageFile, String category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final categoryCode = _categories[category]!;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/wardrobe/$categoryCode/$timestamp.jpg';

    try {
      // 1. 先上傳到 Supabase
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from(_bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      // 2. 上傳成功後保存到本地緩存
      final localFile = await FileCacheService.saveFile(imageFile, storagePath);

      return {
        'path': localFile.path,
        'category': category,
      };
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<WardrobeItemData>> getWardrobeItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final List<WardrobeItemData> items = [];

    // 先嘗試從本地資料夾讀取
    final localItems = await _getLocalWardrobeItems(userId);
    if (localItems.isNotEmpty) return localItems;

    // 本地沒有資料，從後端獲取並緩存
    try {
      // 直接遍歷所有分類
      for (final categoryCode in _categories.values) {
        final filesInCategory = await _supabase.storage.from(_bucket).list(
          path: '$userId/wardrobe/$categoryCode',
        );

        // 如果該分類是空的，跳過
        if (filesInCategory.isEmpty) continue;

        for (final file in filesInCategory) {
          final storagePath = '$userId/wardrobe/$categoryCode/${file.name}';

          try {
            final bytes = await _supabase.storage.from(_bucket).download(storagePath);

            // 創建臨時文件
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/temp_${file.name}');
            await tempFile.writeAsBytes(bytes);

            // 保存到本地緩存
            final localFile = await FileCacheService.saveFile(tempFile, storagePath);
            await tempFile.delete(); // 刪除臨時文件

            final category = _getCategoryFromCode(categoryCode);

            items.add(WardrobeItemData(
              path: localFile.path,
              category: category,
            ));
          } catch (e) {
            // 下載失敗，跳過此項目
            continue;
          }
        }
      }
    } catch (e) {
      // 從後端獲取失敗
      return [];
    }

    return items;
  }

  /// 從本地資料夾讀取所有衣櫃項目
  static Future<List<WardrobeItemData>> _getLocalWardrobeItems(String userId) async {
    final List<WardrobeItemData> items = [];

    try {
      for (final entry in _categories.entries) {
        final categoryName = entry.key;
        final categoryCode = entry.value;

        final files = await FileCacheService.getFiles(
          relativePath: '$userId/wardrobe/$categoryCode',
        );

        for (final file in files) {
          items.add(WardrobeItemData(
            path: file.path,
            category: categoryName,
          ));
        }
      }
    } catch (e) {
      // 讀取本地資料失敗，返回空列表
      return [];
    }

    return items;
  }

  static Future<void> deleteWardrobeItem(String path) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final userIdIndex = path.indexOf(userId);
    if (userIdIndex == -1) return;

    final relativePath = path.substring(userIdIndex);

    await _supabase.storage.from(_bucket).remove([relativePath]);
    await FileCacheService.deleteFile(relativePath);
  }

  static String _getCategoryFromCode(String code) {
    return _categories.entries.firstWhere((e) => e.value == code).key;
  }
}

class WardrobeItemData {
  final String path;
  final String category;

  WardrobeItemData({
    required this.path,
    required this.category,
  });
}