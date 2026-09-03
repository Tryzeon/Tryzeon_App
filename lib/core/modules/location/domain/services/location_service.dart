import 'package:geolocator/geolocator.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';

abstract class LocationService {
  Future<UserLocation?> getUserLocation();

  Future<GeoCoordinates?> getCoordinates();

  Future<LocationPermission> requestPermission();

  Future<bool> hasPermission();
}
