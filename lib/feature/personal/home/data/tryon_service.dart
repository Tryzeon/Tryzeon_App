import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class TryonService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> tryon(
    File clothingImage, {
    String? avatarBase64,
  }) async {
    try {
      // Convert clothing image to base64
      final clothingBytes = await clothingImage.readAsBytes();
      final clothingBase64 = base64Encode(clothingBytes);

      final body = {
        'clothing_image': clothingBase64,
      };

      // 如果有自訂的 avatar base64，加入到 body
      if (avatarBase64 != null) {
        body['avatar_image'] = avatarBase64;
      }

      final response = await _supabase.functions.invoke(
        'tryon',
        body: body,
      );

      return response.data['image'];
    } catch (e) {
      // Error handling - in production use proper logging framework
      return null;
    }
  }

  /// Try on product by URL - downloads image in edge function
  static Future<String?> tryonProduct(
    String productImageUrl, {
    String? avatarBase64,
  }) async {
    try {
      final body = {
        'product_image_url': productImageUrl,
      };

      // 如果有自訂的 avatar base64，加入到 body
      if (avatarBase64 != null) {
        body['avatar_image'] = avatarBase64;
      }

      final response = await _supabase.functions.invoke(
        'tryon',
        body: body,
      );

      return response.data['image'];
    } catch (e) {
      // Error handling - in production use proper logging framework
      return null;
    }
  }
}