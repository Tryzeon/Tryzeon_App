import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'wardrobe';

  static const List<({String zh, String en})> _wardrobeTypes = [
    (zh: '上衣', en: 'top'),
    (zh: '褲子', en: 'pants'),
    (zh: '裙子', en: 'skirt'),
    (zh: '外套', en: 'jacket'),
    (zh: '鞋子', en: 'shoes'),
    (zh: '配件', en: 'accessories'),
    (zh: '其他', en: 'others'),
  ];

  /// 獲取所有衣櫃類型（中文名稱列表）
  static List<String> getWardrobeTypesList() {
    return _wardrobeTypes.map((t) => t.zh).toList();
  }

  /// 根據中文名稱獲取英文代碼
  static String getEnglishCode(String nameZh) {
    final type = _wardrobeTypes.where((t) => t.zh == nameZh).firstOrNull;
    return type?.en ?? nameZh;
  }

  static Future<bool> uploadWardrobeItem(File imageFile, String category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final categoryCode = getEnglishCode(category);
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

  static Future<List<WardrobeItem>> getWardrobeItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final List<WardrobeItem> items = [];

    // 先嘗試從本地資料夾讀取
    final localItems = await _getLocalWardrobeItems(userId);
    if (localItems.isNotEmpty) return localItems;

    try {
      // 本地沒有資料，從後端獲取並緩存
      final typesList = getWardrobeTypesList();

      for (final type in typesList) {
        final categoryCode = getEnglishCode(type);

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

          items.add(WardrobeItem(
            path: localFile.path,
            category: type,
            imageUrl: storagePath,
          ));
        }
      }

      // 按時間戳降序排序
      items.sort((a, b) {
        final timestampA = a.imageUrl.split('/').last.split('.').first;
        final timestampB = b.imageUrl.split('/').last.split('.').first;
        return timestampB.compareTo(timestampA);
      });

      return items;
    } catch (e) {
      print("Error fetching wardrobe items: $e");
      return [];
    }
  }

  /// 從本地資料夾讀取所有衣櫃項目
  static Future<List<WardrobeItem>> _getLocalWardrobeItems(String userId) async {
    final List<WardrobeItem> items = [];

    try {
      final typesList = getWardrobeTypesList();

      for (final type in typesList) {
        final categoryCode = getEnglishCode(type);

        final files = await FileCacheService.getFiles(
          relativePath: '$userId/wardrobe/$categoryCode',
        );

        for (final file in files) {
          final storagePath = '$userId/wardrobe/$categoryCode/${file.path.split('/').last}';

          items.add(WardrobeItem(
            path: file.path,
            category: type,
            imageUrl: storagePath,
          ));
        }
      }

      // 按時間戳降序排序
      items.sort((a, b) {
        final timestampA = a.imageUrl.split('/').last.split('.').first;
        final timestampB = b.imageUrl.split('/').last.split('.').first;
        return timestampB.compareTo(timestampA);
      });

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

class WardrobeItem {
  final String path;
  final String category;
  final String imageUrl;

  WardrobeItem({
    required this.path,
    required this.category,
    required this.imageUrl,
  });
}
