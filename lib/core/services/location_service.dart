import 'package:equatable/equatable.dart';

/// 使用者位置資訊
class UserLocation extends Equatable {
  const UserLocation({
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });

  /// 城市名稱，如「台北市」
  final String city;

  /// 區名稱，如「信義區」
  final String district;

  /// 緯度
  final double latitude;

  /// 經度
  final double longitude;

  /// 完整地址（如「台北市信義區市府路1號」）
  final String fullAddress;

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

  /// 計算與指定地址的接近度分數
  /// 2: 同區, 1: 同城市, 0: 其他
  int proximityScore(final String? address) {
    if (isSameDistrict(address)) return 2;
    if (isSameCity(address)) return 1;
    return 0;
  }

  @override
  List<Object?> get props => [city, district, latitude, longitude, fullAddress];
}

/// 位置服務抽象介面
abstract class LocationService {
  /// 取得使用者所在城市和區
  /// 若無法取得位置（權限拒絕、定位失敗等），返回 null
  Future<UserLocation?> getUserLocation();
}
