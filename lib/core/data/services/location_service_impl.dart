import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tryzeon/core/domain/entities/user_location.dart';
import 'package:tryzeon/core/domain/services/location_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

/// LocationService 實作，使用 Geolocator 和 Geocoding 套件
class LocationServiceImpl implements LocationService {
  @override
  Future<UserLocation?> getUserLocation() async {
    try {
      // 1. 檢查定位服務是否開啟
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.info('位置服務未開啟');
        return null;
      }

      // 2. 檢查並請求權限
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.info('位置權限被拒絕');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.info('位置權限被永久拒絕');
        return null;
      }

      // 3. 取得目前位置
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // 4. 反向地理編碼取得地址
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

      // 5. 解析城市和區
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

      // 6. 組合完整地址
      final addressParts = [
        placemark.administrativeArea,
        placemark.locality,
        placemark.subLocality,
        placemark.thoroughfare,
        placemark.subThoroughfare,
      ].where((final s) => s != null && s.isNotEmpty).join('');

      // 若無法組出完整地址，至少使用城市+區
      final fullAddress = addressParts.isNotEmpty ? addressParts : '$city$district';

      AppLogger.info('使用者位置：$fullAddress');

      return UserLocation(
        city: city,
        district: district,
        latitude: position.latitude,
        longitude: position.longitude,
        fullAddress: fullAddress,
      );
    } catch (e, stackTrace) {
      AppLogger.error('取得位置失敗', e, stackTrace);
      return null;
    }
  }
}
