import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final double? height;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulderWidth;
  final double? sleeveLength;

  UserProfile({
    required this.id,
    required this.name,
    this.height,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.shoulderWidth,
    this.sleeveLength,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      chest: json['chest'] != null ? (json['chest'] as num).toDouble() : null,
      waist: json['waist'] != null ? (json['waist'] as num).toDouble() : null,
      hips: json['hips'] != null ? (json['hips'] as num).toDouble() : null,
      shoulderWidth: json['shoulder_width'] != null ? (json['shoulder_width'] as num).toDouble() : null,
      sleeveLength: json['sleeve_length'] != null ? (json['sleeve_length'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'shoulder_width': shoulderWidth,
      'sleeve_length': sleeveLength,
    };
  }
}

class UserProfileResult {
  final bool success;
  final UserProfile? profile;
  final String? errorMessage;

  UserProfileResult({
    required this.success,
    this.profile,
    this.errorMessage,
  });

  factory UserProfileResult.success(UserProfile profile) {
    return UserProfileResult(success: true, profile: profile);
  }

  factory UserProfileResult.failure(String errorMessage) {
    return UserProfileResult(success: false, errorMessage: errorMessage);
  }
}

class UserProfileService {
  static final _supabase = Supabase.instance.client;
  static const _cacheKey = 'user_profile_cache';

  /// 取得使用者個人資料
  static Future<UserProfileResult> getUserProfile({bool forceRefresh = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return UserProfileResult.failure('使用者未登入');
      }

      if (!forceRefresh) {
        final cached = await _loadFromCache();
        if (cached != null) return UserProfileResult.success(cached);
      }

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = UserProfile.fromJson(response);
      await _saveToCache(profile);
      return UserProfileResult.success(profile);
    } catch (e) {
      return UserProfileResult.failure('取得個人資料失敗: ${e.toString()}');
    }
  }

  /// 更新使用者個人資料
  static Future<UserProfileResult> updateUserProfile({
    String? name,
    double? height,
    double? weight,
    double? chest,
    double? waist,
    double? hips,
    double? shoulderWidth,
    double? sleeveLength,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return UserProfileResult.failure('使用者未登入');
      }

      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name.trim();
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;
      if (chest != null) updateData['chest'] = chest;
      if (waist != null) updateData['waist'] = waist;
      if (hips != null) updateData['hips'] = hips;
      if (shoulderWidth != null) updateData['shoulder_width'] = shoulderWidth;
      if (sleeveLength != null) updateData['sleeve_length'] = sleeveLength;

      final response = await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      final profile = UserProfile.fromJson(response);
      await _saveToCache(profile);
      return UserProfileResult.success(profile);
    } catch (e) {
      return UserProfileResult.failure('更新個人資料失敗: ${e.toString()}');
    }
  }

  /// 儲存到 SharedPreferences
  static Future<void> _saveToCache(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profile.toJson());
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      // 忽略快取錯誤
    }
  }

  /// 從 SharedPreferences 載入
  static Future<UserProfile?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      // 快取損壞，返回 null
      return null;
    }
  }

  /// 清除快取
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      // 忽略錯誤
    }
  }
}
