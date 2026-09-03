import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_location.freezed.dart';

@freezed
sealed class UserLocation with _$UserLocation {
  const factory UserLocation({
    /// 城市名稱，如「台北市」
    required final String city,

    /// 區名稱，如「信義區」
    required final String district,

    required final double latitude,

    required final double longitude,

    /// 完整地址（如「台北市信義區市府路1號」）
    required final String fullAddress,
  }) = _UserLocation;
  const UserLocation._();

  /// 取得城市+區的組合字串，如「台北市信義區」
  String get cityDistrict => '$city$district';

  /// 檢查是否與指定地址在同一個區
  bool isSameDistrict(final String? address) {
    if (address == null || address.isEmpty) return false;
    return address.startsWith(cityDistrict);
  }

  /// 檢查是否與指定地址在同一個城市
  bool isSameCity(final String? address) {
    if (address == null || address.isEmpty) return false;
    return address.startsWith(city);
  }

  /// 2: 同區, 1: 同城市, 0: 其他
  int proximityScore(final String? address) {
    if (isSameDistrict(address)) return 2;
    if (isSameCity(address)) return 1;
    return 0;
  }
}
