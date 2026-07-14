import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_media_datasource.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_media_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/prepare_tryon_avatar_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/save_tryon_media.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/share_tryon_media.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'tryon_providers.g.dart';

// Data Source Providers
@riverpod
TryonRemoteDataSource tryonRemoteDataSource(final Ref ref) {
  return TryonRemoteDataSource(Supabase.instance.client);
}

// Repository Providers
@riverpod
TryOnRepository tryOnRepository(final Ref ref) {
  final tryonDataSource = ref.watch(tryonRemoteDataSourceProvider);

  return TryOnRepositoryImpl(remoteDataSource: tryonDataSource);
}

// Use Case Providers
@riverpod
Tryon tryonUseCase(final Ref ref) {
  final tryOnRepository = ref.watch(tryOnRepositoryProvider);
  return Tryon(tryOnRepository: tryOnRepository);
}

// Media (save/share) — data source, repository, use cases
@riverpod
TryOnMediaDataSource tryOnMediaDataSource(final Ref ref) {
  return TryOnMediaDataSource();
}

@riverpod
TryOnMediaRepository tryOnMediaRepository(final Ref ref) {
  return TryOnMediaRepositoryImpl(dataSource: ref.watch(tryOnMediaDataSourceProvider));
}

@riverpod
SaveTryonMedia saveTryonMediaUseCase(final Ref ref) {
  return SaveTryonMedia(mediaRepository: ref.watch(tryOnMediaRepositoryProvider));
}

@riverpod
ShareTryonMedia shareTryonMediaUseCase(final Ref ref) {
  return ShareTryonMedia(mediaRepository: ref.watch(tryOnMediaRepositoryProvider));
}

@riverpod
PrepareTryonAvatarSource prepareTryonAvatarSourceUseCase(final Ref ref) {
  return PrepareTryonAvatarSource(
    mediaRepository: ref.watch(tryOnMediaRepositoryProvider),
  );
}

/// Mutation orchestrator for try-on. Wraps [Tryon] and additionally
/// pushes the post-mutation usage snapshot into [dailyUsageTodayProvider]'s
/// cache, so the Account card updates without a round trip.
///
/// UI should call this instead of [tryonUseCaseProvider] directly — that way
/// any new try-on entry point inherits the cache-sync side effect for free.
///
/// `keepAlive: true` because the orchestrator is invoked via `ref.read` (no
/// long-lived listener). Without it, autoDispose may tear the provider down
/// mid-await, causing "Cannot use Ref after dispose" when the async body
/// resumes.
@Riverpod(keepAlive: true)
class TryonAction extends _$TryonAction {
  @override
  void build() {}

  Future<Result<TryonResult, Failure>> execute(final TryOnParams params) async {
    final useCase = ref.read(tryonUseCaseProvider);
    final result = await useCase(params);

    final usageCache = ref.read(dailyUsageTodayProvider.notifier);
    if (result.isSuccess) {
      usageCache.syncFromSnapshot(result.get()!.usage);
    } else {
      usageCache.syncFromFailure(result.getError()!);
    }

    return result;
  }
}
