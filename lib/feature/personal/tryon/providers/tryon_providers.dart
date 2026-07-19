import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_media_datasource.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_media_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/resolve_tryon_avatar.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/save_tryon_media.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/share_tryon_media.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon.dart';

part 'tryon_providers.g.dart';

// Data Source Providers
@riverpod
TryonRemoteDataSource tryonRemoteDataSource(final Ref ref) {
  return TryonRemoteDataSource(Supabase.instance.client);
}

// Repository Providers
@riverpod
TryonRepository tryonRepository(final Ref ref) {
  final tryonDataSource = ref.watch(tryonRemoteDataSourceProvider);

  return TryonRepositoryImpl(remoteDataSource: tryonDataSource);
}

// Use Case Providers
@riverpod
Tryon tryonUseCase(final Ref ref) {
  return Tryon(tryonRepository: ref.watch(tryonRepositoryProvider));
}

@riverpod
ResolveTryonAvatar resolveTryonAvatarUseCase(final Ref ref) {
  return ResolveTryonAvatar(mediaRepository: ref.watch(tryonMediaRepositoryProvider));
}

// Media (save/share) — data source, repository, use cases
@riverpod
TryonMediaDataSource tryonMediaDataSource(final Ref ref) {
  return TryonMediaDataSource();
}

@riverpod
TryonMediaRepository tryonMediaRepository(final Ref ref) {
  return TryonMediaRepositoryImpl(dataSource: ref.watch(tryonMediaDataSourceProvider));
}

@riverpod
SaveTryonMedia saveTryonMediaUseCase(final Ref ref) {
  return SaveTryonMedia(mediaRepository: ref.watch(tryonMediaRepositoryProvider));
}

@riverpod
ShareTryonMedia shareTryonMediaUseCase(final Ref ref) {
  return ShareTryonMedia(mediaRepository: ref.watch(tryonMediaRepositoryProvider));
}
