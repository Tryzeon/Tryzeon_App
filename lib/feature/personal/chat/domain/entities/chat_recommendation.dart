import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/outfit_slot.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

part 'chat_recommendation.freezed.dart';

@freezed
sealed class ChatRecommendation with _$ChatRecommendation {
  const factory ChatRecommendation({
    required final String description,
    @Default([]) final List<OutfitSlot> slots,
    final DailyUsage? usage,
  }) = _ChatRecommendation;
}
