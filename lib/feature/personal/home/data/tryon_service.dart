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
    } on FunctionException catch (e) {
      String message;
      switch (e.status) {
        case 403:
          message = '今日試穿次數已達上限，請明日再試或升級方案';
          break;
        case 422:
          message = 'AI 無法辨識圖片，請換一張試試';
          break;
        default:
          message = '伺服器錯誤，請稍後再試';
          break;
      }
      return Result.failure('虛擬試穿失敗', error: e, errorMessage: message);
    } catch (e) {
      return Result.failure('虛擬試穿失敗', error: e);
    }
  }
}
