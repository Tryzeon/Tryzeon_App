import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_data_source.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tryzeon/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/auth/domain/usecases/get_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/send_email_otp.dart';
import 'package:tryzeon/feature/auth/domain/usecases/set_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_in_with_provider.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_out.dart';
import 'package:tryzeon/feature/auth/domain/usecases/verify_email_otp.dart';

// Data Source Providers
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((final ref) {
  return AuthRemoteDataSource(Supabase.instance.client);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((final ref) {
  final isarService = ref.watch(isarServiceProvider);
  return AuthLocalDataSource(isarService);
});

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((final ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  final cacheService = ref.watch(cacheServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    cacheService: cacheService,
  );
});

// Use Case Providers
final signInWithProviderUseCaseProvider = FutureProvider<SignInWithProviderUseCase>((
  final ref,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithProviderUseCase(repository);
});

final sendEmailOtpUseCaseProvider = FutureProvider<SendEmailOtpUseCase>((
  final ref,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return SendEmailOtpUseCase(repository);
});

final verifyEmailOtpUseCaseProvider = FutureProvider<VerifyEmailOtpUseCase>((
  final ref,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyEmailOtpUseCase(repository);
});

final signOutUseCaseProvider = FutureProvider<SignOutUseCase>((final ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

final getLastLoginTypeUseCaseProvider = FutureProvider<GetLastLoginTypeUseCase>((
  final ref,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return GetLastLoginTypeUseCase(repository);
});

final setLastLoginTypeUseCaseProvider = FutureProvider<SetLastLoginTypeUseCase>((
  final ref,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return SetLastLoginTypeUseCase(repository);
});
