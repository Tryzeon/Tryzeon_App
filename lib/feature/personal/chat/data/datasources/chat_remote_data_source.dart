import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Sends the conversation [history] to the `chat` function and returns the
  /// raw response body. Only text messages are forwarded (recommendation-only
  /// bubbles carry no text). Repository parses the body into a [ChatReply].
  Future<Map<String, dynamic>> sendMessage(
    final List<ChatMessage> history, {
    final String? gender,
  }) async {
    final messages = history
        .where((final m) => m.text.trim().isNotEmpty)
        .map((final m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    final response = await _supabase.functions.invoke(
      AppConstants.functionChat,
      body: {'messages': messages, 'gender': ?gender},
    );
    return response.data as Map<String, dynamic>;
  }
}
