import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/models/product_row_mapper.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

/// Owns the chat wire format in both directions, so the repository never touches
/// raw transport JSON. Sends the conversation in the standard `{role, content:
/// [blocks]}` shape and parses the server's reply back into domain entities.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _mappr = PersonalMappr();

  /// Sends the full conversation [history] to the `chat` function and returns the
  /// parsed [ChatReply]. The history is the single source of truth — it is sent
  /// verbatim and the server echoes it plus the new turns.
  Future<ChatReply> sendMessage(final List<ChatMessage> history) async {
    final messages = [for (final m in history) _messageToWire(m)];

    final response = await _supabase.functions.invoke(
      AppConstants.functionChat,
      body: {'messages': messages},
    );
    return parseReply(response.data as Map<String, dynamic>);
  }

  /// Parses the server's reply body into domain entities. Static and pure so it
  /// can be unit-tested directly, without a [SupabaseClient].
  static ChatReply parseReply(final Map<String, dynamic> data) {
    final usageJson = data['usage'] as Map<String, dynamic>?;
    return ChatReply(
      messages: _parseMessages(data['messages'] as List<dynamic>?),
      usage: usageJson == null ? null : DailyUsageModel.fromJson(usageJson).toEntity(),
    );
  }

  // ── domain → wire ──

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

  // ── wire → domain ──

  static List<ChatMessage> _parseMessages(final List<dynamic>? raw) {
    final result = <ChatMessage>[];
    for (final m in raw ?? const []) {
      if (m is! Map<String, dynamic>) continue;
      final role = m['role'] == 'user' ? ChatRole.user : ChatRole.assistant;
      result.add(ChatMessage(role: role, content: _parseBlocks(m['content'] as List<dynamic>?)));
    }
    return result;
  }

  /// Each block is already a resolved real item or a raw tool trace, so we build
  /// the matching [ContentBlock] directly — no extra wardrobe/shop lookups.
  static List<ContentBlock> _parseBlocks(final List<dynamic>? blocksJson) {
    final result = <ContentBlock>[];
    for (final raw in blocksJson ?? const []) {
      if (raw is! Map<String, dynamic>) continue;
      switch (raw['type'] as String?) {
        case 'text':
          final text = (raw['text'] as String? ?? '').trim();
          if (text.isEmpty) continue;
          result.add(ContentBlock.text(text));
        case 'tool_use':
          result.add(
            ContentBlock.toolUse(
              id: raw['id'] as String? ?? '',
              name: raw['name'] as String? ?? '',
              input: (raw['input'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
          );
        case 'tool_result':
          result.add(
            ContentBlock.toolResult(
              toolUseId: raw['tool_use_id'] as String? ?? '',
              content: (raw['content'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
          );
        case 'shop_product':
          final item = raw['item'];
          if (item is! Map<String, dynamic>) continue;
          result.add(
            ContentBlock.shopProduct(
              _mappr.convert<ShopProductModel, ShopProduct>(
                ShopProductModel.fromJson(productRowWithImageUrls(item)),
              ),
            ),
          );
        case 'wardrobe_product':
          final item = raw['item'];
          if (item is! Map<String, dynamic>) continue;
          result.add(
            ContentBlock.wardrobeProduct(
              _mappr.convert<WardrobeItemModel, WardrobeItem>(
                WardrobeItemModel.fromJson(item),
              ),
            ),
          );
      }
    }
    return result;
  }
}
