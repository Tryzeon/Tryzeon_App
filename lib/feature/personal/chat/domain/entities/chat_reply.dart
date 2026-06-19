import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

part 'chat_reply.freezed.dart';

/// The full conversation after a turn — the server echoes the history it was
/// sent plus the new turns it generated — together with the post-call quota
/// snapshot. The client replaces its history with [messages].
@freezed
sealed class ChatReply with _$ChatReply {
  const factory ChatReply({
    @Default([]) final List<ChatMessage> messages,
    final DailyUsage? usage,
  }) = _ChatReply;
}
