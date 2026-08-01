import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_capabilities.freezed.dart';

@freezed
sealed class SubscriptionCapabilities with _$SubscriptionCapabilities {
  const factory SubscriptionCapabilities({
    required final bool hasVideoAccess,
    required final int wardrobeLimit,
    required final int dailyTryonLimit,
    required final int dailyChatLimit,
    required final int dailyVideoLimit,
  }) = _SubscriptionCapabilities;
}
