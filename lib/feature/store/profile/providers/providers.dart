import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/repositories/store_profile_repository_impl.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/get_store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/update_store_profile.dart';
import 'package:typed_result/typed_result.dart';

final storeProfileRemoteDataSourceProvider = Provider<StoreProfileRemoteDataSource>((
  final ref,
) {
  return StoreProfileRemoteDataSource(Supabase.instance.client);
});

final storeProfileLocalDataSourceProvider = Provider<StoreProfileLocalDataSource>((
  final ref,
) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return StoreProfileLocalDataSource(isarService, cacheService);
});

final storeProfileRepositoryProvider = Provider<StoreProfileRepository>((final ref) {
  return StoreProfileRepositoryImpl(
    remoteDataSource: ref.watch(storeProfileRemoteDataSourceProvider),
    localDataSource: ref.watch(storeProfileLocalDataSourceProvider),
  );
});

final getStoreProfileUseCaseProvider = Provider<GetStoreProfile>((final ref) {
  return GetStoreProfile(ref.watch(storeProfileRepositoryProvider));
});

final updateStoreProfileUseCaseProvider = Provider<UpdateStoreProfile>((final ref) {
  return UpdateStoreProfile(ref.watch(storeProfileRepositoryProvider));
});

final storeProfileProvider = FutureProvider.autoDispose<StoreProfile?>((final ref) async {
  final getStoreProfile = ref.watch(getStoreProfileUseCaseProvider);
  final result = await getStoreProfile();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get();
});
