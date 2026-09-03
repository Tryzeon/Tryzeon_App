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
      // Check permission
      if (!await hasPermission()) {
        return null;
      }

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // Reverse-geocode into an address
      try {
        await setLocaleIdentifier('zh_TW');
      } catch (e) {
        AppLogger.info('Failed to set the locale: $e');
      }
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        AppLogger.info('No address information available');
        return null;
      }
      final placemark = placemarks.first;

      // Parse city and district
      final city = placemark.administrativeArea;
      final district = placemark.locality;

      if (city == null || city.isEmpty) {
        AppLogger.info('Could not resolve a city from: $placemark');
        return null;
      }

      if (district == null || district.isEmpty) {
        AppLogger.info('Could not resolve a district from: $placemark');
        return null;
      }

      // Compose the full address
      final addressParts = [
        placemark.administrativeArea,
        placemark.locality,
        placemark.subLocality,
        placemark.thoroughfare,
        placemark.subThoroughfare,
      ].where((final s) => s != null && s.isNotEmpty).join('');

      // If the full address cannot be composed, fall back to city + district
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
