import 'dart:convert';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/models/product_row_mapper.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/usage/usage.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

const _mappr = PersonalMappr();

// ── domain → wire ──

Map<String, dynamic> messageToWire(final ChatMessage m) => {
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

ChatMessage parseMessage(final Map<String, dynamic> raw) => ChatMessage(
  role: raw['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
  content: _parseBlocks(raw['content'] as List<dynamic>?),
);

/// Each block is already a resolved real item or a raw tool trace, so we build
/// the matching [ContentBlock] directly — no extra wardrobe/shop lookups.
List<ContentBlock> _parseBlocks(final List<dynamic>? blocksJson) {
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

// ── NDJSON stream line → event ──

/// Parses one NDJSON line into a [ChatStreamEvent]. Returns null for blank,
/// malformed, or unrecognised lines (defensive — the stream is best-effort UI).
ChatStreamEvent? parseStreamLine(final String line) {
  if (line.trim().isEmpty) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(line);
  } catch (e, st) {
    AppLogger.warning('Failed to parse chat stream line', e, st);
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  switch (decoded['type'] as String?) {
    case 'tool_use':
      return ChatStreamEvent.toolStarted(
        ToolUseBlock(
          id: decoded['id'] as String? ?? '',
          name: decoded['name'] as String? ?? '',
          input: (decoded['input'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );
    case 'tool_result':
      return ChatStreamEvent.toolFinished(
        ToolResultBlock(
          toolUseId: decoded['tool_use_id'] as String? ?? '',
          content: (decoded['content'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );
    case 'done':
      final message = decoded['message'];
      final answer = message is Map<String, dynamic>
          ? parseMessage(message)
          : const ChatMessage(role: ChatRole.assistant, content: []);
      final usageJson = decoded['usage'] as Map<String, dynamic>?;
      return ChatStreamEvent.replied(
        answer: answer,
        usage: usageJson == null ? null : parseDailyUsagePayload(usageJson),
      );
    case 'error':
      return const ChatStreamEvent.failed(ServerFailure());
    default:
      return null;
  }
}
