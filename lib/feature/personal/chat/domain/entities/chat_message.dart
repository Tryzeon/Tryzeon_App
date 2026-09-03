import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

part 'chat_message.freezed.dart';

enum ChatRole { user, assistant }

@freezed
sealed class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required final ChatRole role,
    @Default([]) final List<ContentBlock> content,
  }) = _ChatMessage;
}
