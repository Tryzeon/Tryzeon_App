import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';

part 'chat_message.freezed.dart';

@freezed
sealed class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required final String text,
    required final bool isUser,
    final ChatRecommendation? recommendation,
  }) = _ChatMessage;
}
