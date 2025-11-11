import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class UserProfileService {
  static final _supabase = Supabase.instance.client;
  static const _userProfileTable = 'user_profile';

  // SharedPreferences key
  static const _cacheKey = 'user_profile_cache';

  /// 取得使用者個人資料
  static Future<UserProfileResult> getUserProfile({bool forceRefresh = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return UserProfileResult.failure('使用者未登入');
      }

      if (!forceRefresh) {
        final cachedData = await CacheService.loadJSON(_cacheKey);
        if (cachedData != null) {
          final cachedProfile = UserProfile.fromJson(cachedData);
          return UserProfileResult.success(cachedProfile);
        }
      }

      final response = await _supabase
          .from(_userProfileTable)
          .select()
          .eq('user_id', user.id)
          .single();

      final profile = UserProfile.fromJson(response);

      await CacheService.saveJSON(_cacheKey, profile.toJson());
      
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
          .from(_userProfileTable)
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      final profile = UserProfile.fromJson(response);

      await CacheService.saveJSON(_cacheKey, profile.toJson());

      return UserProfileResult.success(profile);
    } catch (e) {
      return UserProfileResult.failure('更新個人資料失敗: ${e.toString()}');
    }
  }
}

class UserProfile {
  final String userId;
  final String name;
  final double? height;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulderWidth;
  final double? sleeveLength;

  UserProfile({
    required this.userId,
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
      userId: json['user_id'] as String,
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
      'user_id': userId,
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