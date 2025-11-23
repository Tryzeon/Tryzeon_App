import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';

class TryonService {
  static final _supabase = Supabase.instance.client;

  static Future<Result<String>> tryon({
    final String? avatarBase64,
    final String? clothingBase64,
    final String? clothingPath,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      body['avatarBase64'] = avatarBase64;
      body['clothingBase64'] = clothingBase64;
      body['clothingPath'] = clothingPath;

      final response = await _supabase.functions.invoke('tryon', body: body);
      return Result.success(data: response.data['image']);
    } catch (e) {
      return Result.failure('虛擬試穿失敗', error: e);
    }
  }
}
