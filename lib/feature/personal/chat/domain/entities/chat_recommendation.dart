import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/outfit_slot.dart';

part 'chat_recommendation.freezed.dart';

@freezed
sealed class ChatRecommendation with _$ChatRecommendation {
  const factory ChatRecommendation({
    @Default([]) final List<OutfitSlot> slots,
  }) = _ChatRecommendation;
}
