typedef GeoCoordinates = ({double latitude, double longitude});

abstract class GeocodingService {
  Future<GeoCoordinates?> geocodeAddress(final String address);
}
