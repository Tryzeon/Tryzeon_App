import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

part 'chat_message.freezed.dart';

/// Who authored a turn. The standard chat-API shape uses only these two roles —
/// tool calls live in [assistant] messages and their results in [user] messages.
enum ChatRole { user, assistant }

/// One conversation turn: a [role] and an ordered list of [content] blocks. Each
/// renders as its own bubble; a turn may mix text and product blocks.
@freezed
sealed class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required final ChatRole role,
    @Default([]) final List<ContentBlock> content,
  }) = _ChatMessage;
}
