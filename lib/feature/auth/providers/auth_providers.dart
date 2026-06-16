import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tryzeon/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/auth/domain/usecases/delete_account.dart';
import 'package:tryzeon/feature/auth/domain/usecases/get_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/send_email_otp.dart';
import 'package:tryzeon/feature/auth/domain/usecases/set_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_in_with_provider.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_out.dart';
import 'package:tryzeon/feature/auth/domain/usecases/verify_email_otp.dart';

part 'auth_providers.g.dart';

@riverpod
Stream<AuthState> authState(final Ref ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}

@riverpod
bool isAuthenticated(final Ref ref) {
  // Watch the authState stream to properly react to auth changes
  // without manually invalidating (which causes infinite rebuild loops)
  ref.watch(authStateProvider);

  // By watching the stream, this provider will automatically update
  // when auth state changes. The stream updates directly instead of
  // triggering manual invalidation loops.
  return Supabase.instance.client.auth.currentSession != null;
}

@riverpod
User? currentUser(final Ref ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
}

// Data Source Providers
@riverpod
AuthRemoteDataSource authRemoteDataSource(final Ref ref) {
  return AuthRemoteDataSource(Supabase.instance.client);
}

@riverpod
AuthLocalDataSource authLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  return AuthLocalDataSource(isarService);
}

// Repository Provider
@riverpod
AuthRepository authRepository(final Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  final cacheService = ref.watch(cacheServiceProvider);
  final analyticsEventQueueService = ref.watch(analyticsEventQueueServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    cacheService: cacheService,
    analyticsEventQueueService: analyticsEventQueueService,
  );
}

// Use Case Providers
@riverpod
SignInWithProviderUseCase signInWithProviderUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithProviderUseCase(repository);
}

@riverpod
SendEmailOtpUseCase sendEmailOtpUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendEmailOtpUseCase(repository);
}

@riverpod
VerifyEmailOtpUseCase verifyEmailOtpUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyEmailOtpUseCase(repository);
}

@riverpod
SignOutUseCase signOutUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
}

@riverpod
GetLastLoginTypeUseCase getLastLoginTypeUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetLastLoginTypeUseCase(repository);
}

@riverpod
SetLastLoginTypeUseCase setLastLoginTypeUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SetLastLoginTypeUseCase(repository);
}

@riverpod
DeleteAccountUseCase deleteAccountUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return DeleteAccountUseCase(repository);
}
