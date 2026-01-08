import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreProfileRemoteDataSource {
  StoreProfileRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _table = 'store_profile';
  static const _logoBucket = 'store';

  Future<Map<String, dynamic>?> fetchStoreProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .select('id, owner_id, name, address, logo_path')
        .eq('owner_id', user.id)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>> updateStoreProfile(
    final Map<String, dynamic> updates,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .update(updates)
        .eq('owner_id', user.id)
        .select()
        .single();

    return response;
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
        .uploadBinary(
          logoPath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    return logoPath;
  }

  Future<void> deleteLogo(final String logoPath) async {
    await _supabaseClient.storage.from(_logoBucket).remove([logoPath]);
  }

  String getLogoPublicUrl(final String logoPath) {
    return _supabaseClient.storage.from(_logoBucket).getPublicUrl(logoPath);
  }
}
