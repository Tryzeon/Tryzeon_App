import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WardrobeRemoteDataSource {
  WardrobeRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  static const _table = 'wardrobe_items';
  static const _bucket = 'wardrobe';

  Future<List<Map<String, dynamic>>> fetchWardrobeItems() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .select('id, image_path, category, tags, created_at, updated_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<Map<String, dynamic>> createWardrobeItem({
    required final String category,
    required final String imagePath,
    final List<String> tags = const [],
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .insert({
          'user_id': user.id,
          'category': category,
          'image_path': imagePath,
          'tags': tags,
        })
        .select()
        .single();

    return response;
  }

  Future<void> deleteWardrobeItem(final String id) async {
    await _supabaseClient.from(_table).delete().eq('id', id);
  }

  Future<String> uploadImage({
    required final String category,
    required final String fileName,
    required final Uint8List bytes,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

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
    await _supabaseClient.storage.from(_bucket).remove([path]);
  }

  Future<String> createSignedUrl(final String path) async {
    return _supabaseClient.storage.from(_bucket).createSignedUrl(path, 3600);
  }
}
