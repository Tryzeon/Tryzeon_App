import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/core/modules/location/domain/services/location_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<bool> hasPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  @override
  Future<UserLocation?> getUserLocation() async {
    try {
      // 檢查權限
      if (!await hasPermission()) {
        return null;
      }

      // 取得目前位置
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // 反向地理編碼取得地址
      try {
        await setLocaleIdentifier('zh_TW');
      } catch (e) {
        AppLogger.info('無法設定語言環境: $e');
      }
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        AppLogger.info('無法取得地址資訊');
        return null;
      }
      final placemark = placemarks.first;

      // 解析城市和區
      final city = placemark.administrativeArea;
      final district = placemark.locality;

      if (city == null || city.isEmpty) {
        AppLogger.info('無法解析城市：$placemark');
        return null;
      }

      if (district == null || district.isEmpty) {
        AppLogger.info('無法解析區：$placemark');
        return null;
      }

      // 組合完整地址
      final addressParts = [
        placemark.administrativeArea,
        placemark.locality,
        placemark.subLocality,
        placemark.thoroughfare,
        placemark.subThoroughfare,
      ].where((final s) => s != null && s.isNotEmpty).join('');

      // 若無法組出完整地址，至少使用城市+區
      final fullAddress = addressParts.isNotEmpty ? addressParts : '$city$district';

      return UserLocation(
        city: city,
        district: district,
        latitude: position.latitude,
        longitude: position.longitude,
        fullAddress: fullAddress,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get location', e, stackTrace);
      return null;
    }
  }

  @override
  Future<GeoCoordinates?> getCoordinates() async {
    try {
      if (!await hasPermission()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get coordinates', e, stackTrace);
      return null;
    }
  }
}
