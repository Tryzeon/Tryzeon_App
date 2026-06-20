import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

part 'chat_stream_event.freezed.dart';

/// One event from the chat progress stream. Search steps stream live
/// ([ChatToolStarted]/[ChatToolFinished]); the run ends with exactly one
/// terminal event — [ChatReplied] (the answer turn) or [ChatFailed].
@freezed
sealed class ChatStreamEvent with _$ChatStreamEvent {
  const factory ChatStreamEvent.toolStarted(final ToolUseBlock block) = ChatToolStarted;
  const factory ChatStreamEvent.toolFinished(final ToolResultBlock block) = ChatToolFinished;
  const factory ChatStreamEvent.replied({
    required final ChatMessage answer,
    final DailyUsage? usage,
  }) = ChatReplied;
  const factory ChatStreamEvent.failed(final Failure failure) = ChatFailed;
}
