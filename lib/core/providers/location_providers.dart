import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/services/location_service.dart';
import 'package:tryzeon/core/services/location_service_impl.dart';

/// 位置服務 Provider（基礎設施層）
final locationServiceProvider = Provider<LocationService>((final ref) {
  return LocationServiceImpl();
});
