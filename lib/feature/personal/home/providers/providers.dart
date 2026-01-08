import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/avatar_local_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/avatar_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/repositories/avatar_repository_impl.dart';
import 'package:tryzeon/feature/personal/home/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/avatar_repository.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/home/domain/usecases/get_avatar_usecase.dart';
import 'package:tryzeon/feature/personal/home/domain/usecases/tryon_usecase.dart';
import 'package:tryzeon/feature/personal/home/domain/usecases/upload_avatar_usecase.dart';

// Data Source Providers
final avatarRemoteDataSourceProvider = Provider<AvatarRemoteDataSource>((final ref) {
  return AvatarRemoteDataSource(Supabase.instance.client);
});

final avatarLocalDataSourceProvider = Provider<AvatarLocalDataSource>((final ref) {
  return AvatarLocalDataSource(Supabase.instance.client);
});

final tryonRemoteDataSourceProvider = Provider<TryonRemoteDataSource>((final ref) {
  return TryonRemoteDataSource(Supabase.instance.client);
});

// Repository Providers
final avatarRepositoryProvider = Provider<AvatarRepository>((final ref) {
  final avatarRemoteDataSource = ref.watch(avatarRemoteDataSourceProvider);
  final avatarLocalDataSource = ref.watch(avatarLocalDataSourceProvider);

  return AvatarRepositoryImpl(
    avatarRemoteDataSource: avatarRemoteDataSource,
    avatarLocalDataSource: avatarLocalDataSource,
  );
});

final tryOnRepositoryProvider = Provider<TryOnRepository>((final ref) {
  final tryonDataSource = ref.watch(tryonRemoteDataSourceProvider);

  return TryOnRepositoryImpl(tryonDataSource: tryonDataSource);
});

// Use Case Providers
final getAvatarUseCaseProvider = Provider<GetAvatarUseCase>((final ref) {
  final repository = ref.watch(avatarRepositoryProvider);
  return GetAvatarUseCase(repository);
});

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((final ref) {
  final repository = ref.watch(avatarRepositoryProvider);
  return UploadAvatarUseCase(repository);
});

final tryonUseCaseProvider = Provider<TryonUseCase>((final ref) {
  final avatarRepository = ref.watch(avatarRepositoryProvider);
  final tryOnRepository = ref.watch(tryOnRepositoryProvider);
  return TryonUseCase(
    avatarRepository: avatarRepository,
    tryOnRepository: tryOnRepository,
  );
});
