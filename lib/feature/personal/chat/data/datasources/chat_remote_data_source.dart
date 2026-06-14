import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Returns the raw chat function response. Repository parses the body
  /// into a domain entity (text + optional usage snapshot).
  Future<Map<String, dynamic>> getLLMRecommendation(
    final Map<String, String> answers, {
    final String? gender,
  }) async {
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
      AppConstants.functionChat,
      body: {
        'userRequirement': userRequirement,
        'gender': ?gender,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
