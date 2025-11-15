import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;
  static Future<Result<String>> getLLMRecommendation(Map<String, String> answers) async {
    try {
      final prompt = '''
根據以下穿搭需求，請提供具體的穿搭建議：
- 時間：${answers['when'] ?? ''}
- 地點：${answers['where'] ?? ''}
- 對象：${answers['who'] ?? ''}
- 活動：${answers['what'] ?? ''}
- 原因：${answers['why'] ?? ''}
- 風格：${answers['how'] ?? ''}

請提供具體的服裝搭配建議，包括上衣、下身、鞋子和配件的推薦。
''';

      final res = await _supabase.functions.invoke(
        'chat',
        body: {
          'prompt': prompt
        },
      );

      if (res.data != null) {
        return Result.success(data: res.data['text']);
      } else {
        return Result.failure('無法獲取 LLM 回應');
      }
    } catch (e) {
      return Result.failure('獲取穿搭建議失敗', error: e);
    }
  }

}
