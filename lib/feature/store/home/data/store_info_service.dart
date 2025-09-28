import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
  static final _supabase = Supabase.instance.client;
  static const _storesTable = 'stores-info';
  static const _logoBucket = 'store-logos';

  /// 獲取店家資料
  static Future<StoreData?> getStore() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from(_storesTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return StoreData.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 獲取店家名稱
  static Future<String> getStoreName() async {
    final storeData = await getStore();
    return storeData?.storeName ?? '店家';
  }
  
  /// 更新店家資料
  static Future<bool> upsertStore({
    required String storeName,
    required String address,
    String? logoUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = {
        'user_id': userId,
        'store_name': storeName,
        'address': address,
        if (logoUrl != null) 'logo_url': logoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(_storesTable)
          .upsert(data, onConflict: 'user_id');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 上傳店家Logo
  static Future<String?> uploadLogo(File logoFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final fileName = '$userId/logo.jpg';
      final bytes = await logoFile.readAsBytes();

      await _supabase.storage.from(_logoBucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final logoUrl = _supabase.storage.from(_logoBucket).getPublicUrl(fileName);
      
      return logoUrl;
    } catch (e) {
      return null;
    }
  }
}

class StoreData {
  final String id;
  final String userId;
  final String storeName;
  final String address;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreData({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.address,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      id: json['id'],
      userId: json['user_id'],
      storeName: json['store_name'],
      address: json['address'],
      logoUrl: json['logo_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}