import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class TryonService {
  static final _supabase = Supabase.instance.client;

  static Future<TryonResult> tryon(
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
      return TryonResult.success(response.data['image']);
    } catch (e) {
      return TryonResult.failure(e.toString());
    }
  }

  static Future<TryonResult> tryonFromStorage(
    String storagePath, {
    String? avatarBase64,
  }) async {
    try {
      final body = {
        'product_image_url': storagePath,
      };

      // 如果有自訂的 avatar base64，加入到 body
      if (avatarBase64 != null) {
        body['avatar_image'] = avatarBase64;
      }

      final response = await _supabase.functions.invoke(
        'tryon',
        body: body,
      );
      return TryonResult.success(response.data['image']);
    } catch (e) {
      return TryonResult.failure(e.toString());
    }
  }
}

class TryonResult {
  final bool success;
  final String? image;
  final String? errorMessage;

  TryonResult({
    required this.success,
    this.image,
    this.errorMessage,
  });

  factory TryonResult.success(String image) {
    return TryonResult(success: true, image: image);
  }

  factory TryonResult.failure(String errorMessage) {
    return TryonResult(success: false, errorMessage: errorMessage);
  }
}