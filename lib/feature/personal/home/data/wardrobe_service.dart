import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'wardrobe';

  static Future<Map<String, String>?> uploadWardrobeItem(File imageFile, String category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final categoryCode = _getCategoryCode(category);
    final fileName = '$userId/$categoryCode/$timestamp.jpg';
    final bytes = await imageFile.readAsBytes();

    await _supabase.storage.from(_bucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: false,
      ),
    );

    final signedUrl = await _supabase.storage.from(_bucket).createSignedUrl(
      fileName,
      60 * 60 * 24 * 365,
    );
    
    return {
      'id': fileName,
      'url': signedUrl,
      'category': category,
    };
  }

  static Future<List<WardrobeItemData>> getWardrobeItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final List<WardrobeItemData> items = [];
    
    const categories = ['top', 'pants', 'skirt', 'jacket', 'shoes', 'accessories', 'others'];
    for (final categoryCode in categories) {
      final files = await _supabase.storage.from(_bucket).list(path: '$userId/$categoryCode');
      if (files.isEmpty) continue;

      for (final file in files) {
        final signedUrl = await _supabase.storage.from(_bucket).createSignedUrl(
          '$userId/$categoryCode/${file.name}',
          60 * 60 * 24 * 365,
        );
        
        final category = _getCategoryFromCode(categoryCode);
        
        items.add(WardrobeItemData(
          id: '$userId/$categoryCode/${file.name}',
          url: signedUrl,
          category: category,
        ));
      }
    }

    return items;
  }

  static Future<void> deleteWardrobeItem(String itemId) async {
    await _supabase.storage.from(_bucket).remove([itemId]);
  }

  static String _getCategoryCode(String category) {
    const predefinedCategories = {
      '上衣': 'top',
      '褲子': 'pants',
      '裙子': 'skirt',
      '外套': 'jacket',
      '鞋子': 'shoes',
      '配件': 'accessories',
      '其他': 'others',
    };
    
    return predefinedCategories[category]!;
  }

  static String _getCategoryFromCode(String code) {
    const codeToCategory = {
      'top': '上衣',
      'pants': '褲子',
      'skirt': '裙子',
      'jacket': '外套',
      'shoes': '鞋子',
      'accessories': '配件',
      'others': '其他',
    };
    
    return codeToCategory[code]!;
  }
}

class WardrobeItemData {
  final String id;
  final String url;
  final String category;

  WardrobeItemData({
    required this.id,
    required this.url,
    required this.category,
  });
}