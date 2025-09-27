import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class TryonService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> uploadClothingForTryon(File clothingImage, String? avatarUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || avatarUrl == null) return null;

    try {
      // Convert clothing image to base64
      final clothingBytes = await clothingImage.readAsBytes();
      final clothingBase64 = base64Encode(clothingBytes);

      // Call tryon endpoint with both images
      final response = await _supabase.functions.invoke(
        'tryon',
        body: {
          'user_id': userId,
          'clothing_image': clothingBase64,
          'avatar_url': avatarUrl,
        },
      );

      if (response.data != null && response.data['image'] != null) {
        // Return the base64 image data URL directly
        return response.data['image'];
      }

      return null;
    } catch (e) {
      // Error handling - in production use proper logging framework
      return null;
    }
  }
}