import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileRemoteDataSource {
  StoreProfileRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _table = 'store_profile';
  static const _logoBucket = 'store';

  Future<StoreProfileModel?> fetchStoreProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .select('id, owner_id, name, address, logo_path, created_at, updated_at')
        .eq('owner_id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final map = Map<String, dynamic>.from(response);
    final logoPath = map['logo_path'] as String?;
    if (logoPath != null) {
      map['logo_url'] = getLogoPublicUrl(logoPath);
    }

    return StoreProfileModel.fromJson(map);
  }

  Future<StoreProfileModel> updateStoreProfile(final StoreProfileModel profile) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final json = profile.toJson()
      ..remove('id')
      ..remove('owner_id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('logo_url');

    final response = await _supabaseClient
        .from(_table)
        .update(json)
        .eq('owner_id', user.id)
        .select()
        .single();

    final map = Map<String, dynamic>.from(response);
    final logoPath = map['logo_path'] as String?;
    if (logoPath != null) {
      map['logo_url'] = getLogoPublicUrl(logoPath);
    }

    return StoreProfileModel.fromJson(map);
  }

  Future<String> uploadLogo(final File image) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final imageName = p.basename(image.path);
    final logoPath = '${user.id}/logo/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabaseClient.storage
        .from(_logoBucket)
        .uploadBinary(logoPath, bytes, fileOptions: FileOptions(contentType: mimeType));

    return logoPath;
  }

  Future<void> deleteLogo(final String logoPath) async {
    await _supabaseClient.storage.from(_logoBucket).remove([logoPath]);
  }

  String getLogoPublicUrl(final String logoPath) {
    return _supabaseClient.storage.from(_logoBucket).getPublicUrl(logoPath);
  }
}
