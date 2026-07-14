import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/store_images_api_provider.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
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

@riverpod
Future<StoreProfile?> storeProfile(final Ref ref) async {
  final isLoggedIn = ref.watch(isAuthenticatedProvider);
  if (!isLoggedIn) return null;

  final getStoreProfile = ref.watch(getStoreProfileUseCaseProvider);
  final result = await getStoreProfile();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get();
}

/// 強制刷新店家資料和標誌
Future<void> refreshStoreProfile(final WidgetRef ref) async {
  final getStoreProfileUseCase = ref.read(getStoreProfileUseCaseProvider);
  await getStoreProfileUseCase(forceRefresh: true);
  try {
    ref.invalidate(storeProfileProvider);
    await ref.read(storeProfileProvider.future);
  } catch (e, st) {
    // Provider 刷新失敗時（例如網絡錯誤），忽略異常
    // Provider 會自動進入 error 狀態，UI 會顯示 ErrorView 或舊資料
    AppLogger.warning('Failed to refresh store profile', e, st);
  }
}
