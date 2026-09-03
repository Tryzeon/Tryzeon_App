import 'dart:convert';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/shop/shop.dart';
import 'package:tryzeon/feature/personal/usage/usage.dart';
import 'package:tryzeon/feature/personal/wardrobe/wardrobe.dart';

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
  ShopProductBlock(:final product) => {'type': 'product', 'id': product.id},
  WardrobeProductBlock(:final item) => {'type': 'wardrobe', 'id': item.id},
};

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
      case 'product':
        final item = raw['item'];
        if (item is! Map<String, dynamic>) continue;
        result.add(ContentBlock.shopProduct(decodeShopProductRow(item)));
      case 'wardrobe':
        final item = raw['item'];
        if (item is! Map<String, dynamic>) continue;
        result.add(ContentBlock.wardrobeProduct(decodeWardrobeItemRow(item)));
    }
  }
  return result;
}

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
      if (decoded['code'] == 'RATE_LIMIT_EXCEEDED') {
        return ChatStreamEvent.failed(
          RateLimitFailure(usagePayload: decoded['usage'] as Map<String, dynamic>?),
        );
      }
      return const ChatStreamEvent.failed(ServerFailure());
    default:
      return null;
  }
}
