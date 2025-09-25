import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  static Future<String?> uploadAvatar(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final fileName = '$userId/avatar.jpg';
    final bytes = await imageFile.readAsBytes();

    await _supabase.storage.from(_bucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    final signedUrl = await _supabase.storage.from(_bucket).createSignedUrl(
      fileName,
      60 * 60 * 24 * 365,
    );
    
    return signedUrl;
  }

  static Future<String?> getAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final files = await _supabase.storage.from(_bucket).list(path: userId);
    
    if (files.isEmpty) return null;

    final signedUrl = await _supabase.storage.from(_bucket).createSignedUrl(
      '$userId/avatar.jpg',
      60 * 60 * 24 * 365,
    );

    return signedUrl;
  }

}