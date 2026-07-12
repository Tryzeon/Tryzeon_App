import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileRemoteDataSource {
  StoreProfileRemoteDataSource(this._supabaseClient, this._storeImagesApi);

  final SupabaseClient _supabaseClient;
  final StoreImagesApi _storeImagesApi;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;

  Future<StoreProfileModel?> getStoreProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select(
          'id, owner_id, name, slug, address, latitude, longitude, logo_path, channels, order_contacts, created_at, updated_at',
        )
        .eq('owner_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return StoreProfileModel.fromJson(_withLogoUrl(response));
  }

  Future<StoreProfileModel> updateStoreProfile(final StoreProfileModel profile) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final json = profile.toJson()
      ..remove('id')
      ..remove('owner_id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('logo_url');

    final response = await _supabaseClient
        .from(_storeProfileTable)
        .update(json)
        .eq('owner_id', user.id)
        .select()
        .single();

    return StoreProfileModel.fromJson(_withLogoUrl(response));
  }

  Future<String> uploadLogo({
    required final String storeId,
    required final File image,
  }) async {
    return _storeImagesApi.uploadStoreLogo(storeId: storeId, logo: image);
  }

  Future<void> deleteLogo({
    required final String storeId,
    required final String key,
  }) async {
    return _storeImagesApi.deleteImages(storeId: storeId, keys: [key]);
  }

  Map<String, dynamic> _withLogoUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final logoPath = map['logo_path'] as String?;
    if (logoPath != null && logoPath.isNotEmpty) {
      map['logo_url'] = StoreImagesApi.publicUrl(logoPath);
    }
    return map;
  }
}
