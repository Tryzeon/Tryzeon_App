import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_data_source.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tryzeon/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/auth/domain/usecases/get_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/set_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_in_with_provider.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_out.dart';

// Data Source Providers
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((final ref) {
  return AuthRemoteDataSource(Supabase.instance.client);
});

final authLocalDataSourceProvider = FutureProvider<AuthLocalDataSource>((
  final ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return AuthLocalDataSource(prefs);
});

// Repository Provider
final authRepositoryProvider = FutureProvider<AuthRepository>((final ref) async {
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  final localDataSource = await ref.read(authLocalDataSourceProvider.future);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// Use Case Providers
final signInWithProviderUseCaseProvider = FutureProvider<SignInWithProviderUseCase>((
  final ref,
) async {
  final repository = await ref.read(authRepositoryProvider.future);
  return SignInWithProviderUseCase(repository);
});

final signOutUseCaseProvider = FutureProvider<SignOutUseCase>((final ref) async {
  final repository = await ref.read(authRepositoryProvider.future);
  return SignOutUseCase(repository);
});

final getLastLoginTypeUseCaseProvider = FutureProvider<GetLastLoginTypeUseCase>((
  final ref,
) async {
  final repository = await ref.read(authRepositoryProvider.future);
  return GetLastLoginTypeUseCase(repository);
});

final setLastLoginTypeUseCaseProvider = FutureProvider<SetLastLoginTypeUseCase>((
  final ref,
) async {
  final repository = await ref.read(authRepositoryProvider.future);
  return SetLastLoginTypeUseCase(repository);
});
