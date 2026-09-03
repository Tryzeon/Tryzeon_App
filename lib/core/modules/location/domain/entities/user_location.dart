import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_location.freezed.dart';

@freezed
sealed class UserLocation with _$UserLocation {
  const factory UserLocation({
    required final String city,

    required final String district,

    required final double latitude,

    required final double longitude,

    required final String fullAddress,
  }) = _UserLocation;
  const UserLocation._();

  String get cityDistrict => '$city$district';

  bool isSameDistrict(final String? address) {
    if (address == null || address.isEmpty) return false;
    return address.startsWith(cityDistrict);
  }

  bool isSameCity(final String? address) {
    if (address == null || address.isEmpty) return false;
    return address.startsWith(city);
  }

  int proximityScore(final String? address) {
    if (isSameDistrict(address)) return 2;
    if (isSameCity(address)) return 1;
    return 0;
  }
}
