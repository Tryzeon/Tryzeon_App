import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/cache_service_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/mappers/analytics_mappr.dart';
import 'package:tryzeon/core/modules/analytics/data/models/analytics_event_model.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_service.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/auth_identity/data/services/auth_identity_service_impl.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';
import 'package:tryzeon/core/modules/location/data/services/geocoding_service_impl.dart';
import 'package:tryzeon/core/modules/location/data/services/location_service_impl.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/core/modules/location/domain/services/location_service.dart';

part 'core_providers.g.dart';

const _mappr = AnalyticsMappr();

/// Analytics Remote DataSource Provider
@riverpod
AnalyticsRemoteDataSource analyticsRemoteDataSource(final Ref ref) {
  return AnalyticsRemoteDataSource(Supabase.instance.client);
}

/// Analytics Event Queue Service Provider
@Riverpod(keepAlive: true)
AnalyticsEventQueueService analyticsEventQueueService(final Ref ref) {
  final analyticsDataSource = ref.watch(analyticsRemoteDataSourceProvider);

  return AnalyticsEventQueueService(
    uploadCallback: (final events) {
      final models = _mappr.convertList<AnalyticsEvent, AnalyticsEventModel>(events);
      return analyticsDataSource.uploadAnalyticsEvents(models);
    },
  );
}

/// Location Service Provider
@riverpod
LocationService locationService(final Ref ref) {
  return LocationServiceImpl();
}

/// Geocoding Service Provider
@riverpod
GeocodingService geocodingService(final Ref ref) {
  return GeocodingServiceImpl();
}

/// Cache Service Provider
@Riverpod(keepAlive: true)
CacheService cacheService(final Ref ref) {
  return CacheServiceImpl();
}

/// Isar Database Service Provider
@Riverpod(keepAlive: true)
IsarService isarService(final Ref ref) {
  return IsarService();
}

/// Cache Entry Local DataSource Provider
@Riverpod(keepAlive: true)
CacheEntryLocalDataSource cacheEntryLocalDataSource(final Ref ref) {
  return CacheEntryLocalDataSource(ref.watch(isarServiceProvider));
}

/// Auth Identity Service Provider
@Riverpod(keepAlive: true)
AuthIdentityService authIdentityService(final Ref ref) {
  return AuthIdentityServiceImpl(Supabase.instance.client.auth);
}
