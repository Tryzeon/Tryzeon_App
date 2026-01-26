import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/data/services/cache_service_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/data/services/location_service_impl.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/core/domain/services/location_service.dart';

/// Location Service Provider
final locationServiceProvider = Provider<LocationService>((final ref) {
  return LocationServiceImpl();
});

/// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((final ref) {
  return CacheServiceImpl();
});

/// Isar Database Service Provider
final isarServiceProvider = Provider<IsarService>((final ref) {
  return IsarService();
});
