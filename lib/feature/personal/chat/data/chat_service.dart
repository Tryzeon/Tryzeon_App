import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;
  static Future<Result<String>> getLLMRecommendation(
    final Map<String, String> answers,
  ) async {
    try {
      final userRequirement =
          '''
- 時間：${answers['when'] ?? ''}
- 地點：${answers['where'] ?? ''}
- 對象：${answers['who'] ?? ''}
- 活動：${answers['what'] ?? ''}
- 原因：${answers['why'] ?? ''}
- 風格：${answers['how'] ?? ''}
''';

      final response = await _supabase.functions.invoke(
        'chat',
        body: {'userRequirement': userRequirement},
      );
      return Result.success(data: response.data['text']);
    } catch (e) {
      return Result.failure('獲取穿搭建議失敗', error: e);
    }
  }
}
