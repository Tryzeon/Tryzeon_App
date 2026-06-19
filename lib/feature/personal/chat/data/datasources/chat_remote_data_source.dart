import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Sends the full conversation [history] to the `chat` function and returns the
  /// raw response body. The history is the single source of truth — it is sent
  /// verbatim in the standard `{role, content: [blocks]}` shape and the server
  /// returns the new turns. Repository parses the body into a [ChatReply].
  Future<Map<String, dynamic>> sendMessage(final List<ChatMessage> history) async {
    final messages = [for (final m in history) _messageToWire(m)];

    final response = await _supabase.functions.invoke(
      AppConstants.functionChat,
      body: {'messages': messages},
    );
    return response.data as Map<String, dynamic>;
  }

  Map<String, dynamic> _messageToWire(final ChatMessage m) => {
    'role': m.role.name,
    'content': [for (final b in m.content) _blockToWire(b)],
  };

  /// Products are sent by id only — their full data is already replayed in the
  /// paired tool_result, so the model needs just the reference.
  Map<String, dynamic> _blockToWire(final ContentBlock block) => switch (block) {
    TextBlock(:final text) => {'type': 'text', 'text': text},
    ToolUseBlock(:final id, :final name, :final input) => {
      'type': 'tool_use',
      'id': id,
      'name': name,
      'input': input,
    },
    ToolResultBlock(:final toolUseId, :final content) => {
      'type': 'tool_result',
      'tool_use_id': toolUseId,
      'content': content,
    },
    ShopProductBlock(:final product) => {'type': 'shop_product', 'id': product.id},
    WardrobeProductBlock(:final item) => {'type': 'wardrobe_product', 'id': item.id},
  };
}
