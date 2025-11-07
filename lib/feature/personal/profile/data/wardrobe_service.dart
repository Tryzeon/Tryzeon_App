import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';
import 'package:tryzeon/feature/personal/shop/data/product_type_filter_service.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'wardrobe';

  static Future<bool> uploadWardrobeItem(File imageFile, String category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final categoryCode = await ProductTypeService.getEnglishCode(category);
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
      await FileCacheService.saveFile(imageFile, storagePath);

      return true;
    } catch (e) {
      print("Error uploading wardrobe item: $e");
      return false;
    }
  }

  static Future<List<WardrobeItemData>> getWardrobeItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final List<WardrobeItemData> items = [];

    // 先嘗試從本地資料夾讀取
    final localItems = await _getLocalWardrobeItems(userId);
    if (localItems.isNotEmpty) return localItems;

    try {
      // 本地沒有資料，從後端獲取並緩存
      final typesList = await ProductTypeService.getProductTypesList();

      for (final type in typesList) {
        final categoryCode = await ProductTypeService.getEnglishCode(type);

        final filesInCategory = await _supabase.storage.from(_bucket).list(
          path: '$userId/wardrobe/$categoryCode',
        );

        for (final file in filesInCategory) {
          final storagePath = '$userId/wardrobe/$categoryCode/${file.name}';

          final bytes = await _supabase.storage.from(_bucket).download(storagePath);

          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_${file.name}');
          await tempFile.writeAsBytes(bytes);

          final localFile = await FileCacheService.saveFile(tempFile, storagePath);
          await tempFile.delete();

          items.add(WardrobeItemData(
            path: localFile.path,
            category: type,
            imageUrl: storagePath,
          ));
        }
      }
      return items;
    } catch (e) {
      print("Error fetching wardrobe items: $e");
      return [];
    }
  }

  /// 從本地資料夾讀取所有衣櫃項目
  static Future<List<WardrobeItemData>> _getLocalWardrobeItems(String userId) async {
    final List<WardrobeItemData> items = [];

    try {
      final typesList = await ProductTypeService.getProductTypesList();

      for (final type in typesList) {
        final categoryCode = await ProductTypeService.getEnglishCode(type);

        final files = await FileCacheService.getFiles(
          relativePath: '$userId/wardrobe/$categoryCode',
        );

        for (final file in files) {
          final storagePath = '$userId/wardrobe/$categoryCode/${file.path.split('/').last}';

          items.add(WardrobeItemData(
            path: file.path,
            category: type,
            imageUrl: storagePath,
          ));
        }
      }

      return items;
    } catch (e) {
      print("Error fetching local wardrobe items: $e");
      return [];
    }
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
}

class WardrobeItemData {
  final String path;
  final String category;
  final String imageUrl;

  WardrobeItemData({
    required this.path,
    required this.category,
    required this.imageUrl,
  });
}
