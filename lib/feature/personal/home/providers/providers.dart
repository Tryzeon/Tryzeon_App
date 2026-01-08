import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/home/domain/usecases/tryon_usecase.dart';
import 'package:tryzeon/feature/personal/profile/providers/providers.dart';

// Data Source Providers
final tryonRemoteDataSourceProvider = Provider<TryonRemoteDataSource>((final ref) {
  return TryonRemoteDataSource(Supabase.instance.client);
});

// Repository Providers
final tryOnRepositoryProvider = Provider<TryOnRepository>((final ref) {
  final tryonDataSource = ref.watch(tryonRemoteDataSourceProvider);

  return TryOnRepositoryImpl(tryonDataSource: tryonDataSource);
});

// Use Case Providers
final tryonUseCaseProvider = Provider<TryonUseCase>((final ref) {
  final userProfileRepository = ref.watch(userProfileRepositoryProvider);
  final tryOnRepository = ref.watch(tryOnRepositoryProvider);
  return TryonUseCase(
    userProfileRepository: userProfileRepository,
    tryOnRepository: tryOnRepository,
  );
});
