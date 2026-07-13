import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';

import '../models/create_wardrobe_item_request.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeRemoteDataSource {
  WardrobeRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  static const _wardrobeItemTable = AppConstants.tableWardrobeItems;
  static const _bucket = AppConstants.bucketWardrobeImages;

  Future<List<WardrobeItemModel>> getWardrobeItems() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_wardrobeItemTable)
        .select('id, image_path, category, tags, created_at, updated_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((final e) {
      return WardrobeItemModel.fromJson(
        Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
      );
    }).toList();
  }

  Future<WardrobeItemModel> createWardrobeItem(
    final CreateWardrobeItemRequest request,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final json = request.toJson();
    json['user_id'] = user.id;

    final response = await _supabaseClient
        .from(_wardrobeItemTable)
        .insert(json)
        .select()
        .single();

    return WardrobeItemModel.fromJson(response);
  }

  Future<void> deleteWardrobeItem(final String id) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    await _supabaseClient
        .from(_wardrobeItemTable)
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<WardrobeItemModel> updateWardrobeItemTags({
    required final String id,
    required final List<String> tags,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_wardrobeItemTable)
        .update({'tags': tags})
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

    return WardrobeItemModel.fromJson(response);
  }

  Future<String> uploadImage({
    required final String category,
    required final String fileName,
    required final Uint8List bytes,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final imagePath = '${user.id}/$category/$fileName';
    final contentType = lookupMimeType(fileName);

    await _supabaseClient.storage
        .from(_bucket)
        .uploadBinary(
          imagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    return imagePath;
  }

  Future<void> deleteImage(final String path) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    await _supabaseClient.storage.from(_bucket).remove([path]);
  }

  Future<String> createSignedUrl(final String path) async {
    return _supabaseClient.storage
        .from(_bucket)
        .createSignedUrl(path, AppConstants.signedUrlTtlSeconds);
  }
}
