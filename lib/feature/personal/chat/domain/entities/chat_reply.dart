import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

part 'chat_reply.freezed.dart';

/// One LLM turn. Render whatever is present: [message] as a text bubble,
/// [recommendation] as a RecommendationBubble. Both may be set, or neither
/// (caller shows a fallback). [usage] is the post-call quota snapshot.
@freezed
sealed class ChatReply with _$ChatReply {
  const factory ChatReply({
    final String? message,
    final ChatRecommendation? recommendation,
    final DailyUsage? usage,
  }) = _ChatReply;
}
