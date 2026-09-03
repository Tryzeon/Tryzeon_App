import 'package:geocoding/geocoding.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

/// Backed by the platform-native geocoder (iOS/Android), so no API key.
class GeocodingServiceImpl implements GeocodingService {
  @override
  Future<GeoCoordinates?> geocodeAddress(final String address) async {
    if (address.trim().isEmpty) return null;
    try {
      try {
        await setLocaleIdentifier('zh_TW');
      } catch (e) {
        AppLogger.info('無法設定 geocoding 語言環境: $e');
      }
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      final first = locations.first;
      return (latitude: first.latitude, longitude: first.longitude);
    } catch (e, stackTrace) {
      AppLogger.warning('Geocoding failed for "$address"', e, stackTrace);
      return null;
    }
  }
}
