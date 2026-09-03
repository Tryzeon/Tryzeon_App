import 'package:geolocator/geolocator.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';

abstract class LocationService {
  /// 取得使用者所在城市和區
  /// 若無法取得位置（權限拒絕、定位失敗等），返回 null
  Future<UserLocation?> getUserLocation();

  /// 取得目前位置座標(僅經緯度)
  /// 無權限或定位失敗時返回 null。
  Future<GeoCoordinates?> getCoordinates();

  /// 回傳最終的權限狀態，以便 UI 決定是否引導去設定
  Future<LocationPermission> requestPermission();

  Future<bool> hasPermission();
}
