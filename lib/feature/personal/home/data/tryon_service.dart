import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';

class TryonService {
  static final _supabase = Supabase.instance.client;

  static Future<Result<String>> tryon({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      body['avatarBase64'] = avatarBase64;
      body['avatarPath'] = avatarPath;
      body['clothesBase64'] = clothesBase64;
      body['clothesPath'] = clothesPath;

      final response = await _supabase.functions.invoke('tryon', body: body);
      return Result.success(data: response.data['image']);
    } catch (e) {
      return Result.failure('虛擬試穿失敗', error: e);
    }
  }
}
