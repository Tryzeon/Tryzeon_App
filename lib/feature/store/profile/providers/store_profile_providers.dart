import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/store_images_api_provider.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/repositories/store_profile_repository_impl.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/get_store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/update_store_profile.dart';
import 'package:typed_result/typed_result.dart';

part 'store_profile_providers.g.dart';

@riverpod
StoreProfileRemoteDataSource storeProfileRemoteDataSource(final Ref ref) {
  return StoreProfileRemoteDataSource(
    Supabase.instance.client,
    ref.watch(storeImagesApiProvider),
  );
}

@riverpod
StoreProfileLocalDataSource storeProfileLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return StoreProfileLocalDataSource(
    isarService,
    cacheService,
    cacheEntryLocalDataSource,
  );
}

@riverpod
StoreProfileRepository storeProfileRepository(final Ref ref) {
  return StoreProfileRepositoryImpl(
    remoteDataSource: ref.watch(storeProfileRemoteDataSourceProvider),
    localDataSource: ref.watch(storeProfileLocalDataSourceProvider),
  );
}

@riverpod
GetStoreProfile getStoreProfileUseCase(final Ref ref) {
  return GetStoreProfile(ref.watch(storeProfileRepositoryProvider));
}

@riverpod
UpdateStoreProfile updateStoreProfileUseCase(final Ref ref) {
  return UpdateStoreProfile(ref.watch(storeProfileRepositoryProvider));
}

/// The signed-in store's profile, and the owner of store-profile refreshes.
/// The `Notifier` suffix is stripped by the generator, so the provider stays
/// `storeProfileProvider` while the class name avoids colliding with the
/// `StoreProfile` entity.
@riverpod
class StoreProfileNotifier extends _$StoreProfileNotifier {
  @override
  Future<StoreProfile?> build() async {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    if (!isLoggedIn) return null;

    final getStoreProfile = ref.watch(getStoreProfileUseCaseProvider);
    final result = await getStoreProfile();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get();
  }

  /// Force-refreshes the store profile and its logo from the server. Swallows
  /// errors — the provider drops into an error state and the UI shows an
  /// `ErrorView` or the previous data.
  Future<void> refresh() async {
    await ref.read(getStoreProfileUseCaseProvider)(forceRefresh: true);
    ref.invalidateSelf();
    try {
      await future;
    } catch (e, st) {
      AppLogger.warning('Failed to refresh store profile', e, st);
    }
  }
}

@riverpod
class StoreProfileEditNotifier extends _$StoreProfileEditNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Applies the store owner's edits to the current profile. Only the fields
  /// the form owns are passed in — the profile to merge them onto is read
  /// here, so a stale form can't clobber server-owned fields.
  ///
  /// `addressUnresolved` is true when a non-empty address could not be
  /// geocoded: the save still succeeded, but the store won't appear in
  /// distance-sorted results, so the caller should say so.
  Future<Result<({bool addressUnresolved}), Failure>> save({
    required final String name,
    required final String? address,
    required final Set<StoreChannel> channels,
    required final List<StoreOrderContact> orderContacts,
    final File? logoFile,
  }) async {
    // Kept alive for the duration, so a form popped mid-save doesn't dispose
    // this notifier out from under the pending `state` write.
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final original = await ref.read(storeProfileProvider.future);
      if (original == null) {
        state = const AsyncData(null);
        return const Err(AuthFailure('無法獲取店家資訊，請重新登入'));
      }

      final located = await _resolveCoordinates(original: original, address: address);

      final result = await ref.read(updateStoreProfileUseCaseProvider)(
        original: original,
        target: original.copyWith(
          name: name,
          address: address,
          latitude: located.latitude,
          longitude: located.longitude,
          channels: channels,
          orderContacts: orderContacts,
        ),
        logoFile: logoFile,
      );

      if (result.isFailure) {
        state = AsyncError(result.getError()!, StackTrace.current);
        return Err(result.getError()!);
      }

      ref.invalidate(storeProfileProvider);
      state = const AsyncData(null);
      return Ok((addressUnresolved: located.addressUnresolved));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save store profile', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return Err(mapExceptionToFailure(e));
    } finally {
      link.close();
    }
  }

  /// Geocodes [address] when it differs from [original]'s, keeping the existing
  /// coordinates when it didn't change and clearing them when it was removed.
  /// A geocoding miss is not a failure — the profile still saves.
  Future<({double? latitude, double? longitude, bool addressUnresolved})>
  _resolveCoordinates({
    required final StoreProfile original,
    required final String? address,
  }) async {
    if (address == original.address) {
      return (
        latitude: original.latitude,
        longitude: original.longitude,
        addressUnresolved: false,
      );
    }

    if (address == null || address.isEmpty) {
      return (latitude: null, longitude: null, addressUnresolved: false);
    }

    final coords = await ref.read(geocodingServiceProvider).geocodeAddress(address);
    return (
      latitude: coords?.latitude,
      longitude: coords?.longitude,
      addressUnresolved: coords == null,
    );
  }
}
