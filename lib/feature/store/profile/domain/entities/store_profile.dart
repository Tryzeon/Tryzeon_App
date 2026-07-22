import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

part 'store_profile.freezed.dart';

@freezed
sealed class StoreProfileDraft with _$StoreProfileDraft {
  const factory StoreProfileDraft({
    required final String name,
    required final Set<StoreChannel> channels,
    final String? address,
    final double? latitude,
    final double? longitude,
    @Default(<StoreOrderContact>[]) final List<StoreOrderContact> orderContacts,
  }) = _StoreProfileDraft;
}

@freezed
sealed class StoreProfile with _$StoreProfile {
  const factory StoreProfile({
    required final String id,
    required final String ownerId,
    required final String name,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    required final Set<StoreChannel> channels,
    final String? slug,
    final String? address,
    final double? latitude,
    final double? longitude,
    final String? logoPath,
    final String? logoUrl,
    @Default(<StoreOrderContact>[]) final List<StoreOrderContact> orderContacts,
  }) = _StoreProfile;
}

@freezed
sealed class UpdateStoreProfileParams with _$UpdateStoreProfileParams {
  const factory UpdateStoreProfileParams({
    required final StoreProfile original,
    required final StoreProfileDraft draft,
    final File? logoFile,
  }) = _UpdateStoreProfileParams;
}

extension StoreProfileApplyDraft on StoreProfile {
  StoreProfile applyDraft(final StoreProfileDraft draft) => copyWith(
    name: draft.name,
    address: draft.address,
    latitude: draft.latitude,
    longitude: draft.longitude,
    channels: draft.channels,
    orderContacts: draft.orderContacts,
  );
}
