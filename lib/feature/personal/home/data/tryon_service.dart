import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class TryonResult {
  final String? image;
  final String? error;

  TryonResult({
    this.image,
    this.error,
  });
}

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
      // Success case
      return TryonResult(image: response.data['image']);
    } on FunctionException catch (e) {
      return TryonResult(error: e.details['error']);
    } catch (e) {
      return TryonResult(error: e.toString());
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

      return TryonResult(image: response.data['image']);
    } on FunctionException catch (e) {
      return TryonResult(error: e.details['error']);
    } catch (e) {
      return TryonResult(error: e.toString());
    }
  }
}