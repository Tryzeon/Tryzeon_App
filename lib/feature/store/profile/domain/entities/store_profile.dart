import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';

part 'store_profile.freezed.dart';

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
  }) = _StoreProfile;
}
