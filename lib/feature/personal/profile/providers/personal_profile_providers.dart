import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_style_preferences.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_profile.dart';
import 'package:typed_result/typed_result.dart';

part 'personal_profile_providers.g.dart';

@riverpod
UserProfileRemoteDataSource userProfileRemoteDataSource(final Ref ref) {
  return UserProfileRemoteDataSource(Supabase.instance.client);
}

@riverpod
UserProfileLocalDataSource userProfileLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return UserProfileLocalDataSource(isarService, cacheService, cacheEntryLocalDataSource);
}

@riverpod
UserProfileRepository userProfileRepository(final Ref ref) {
  return UserProfileRepositoryImpl(
    remoteDataSource: ref.watch(userProfileRemoteDataSourceProvider),
    localDataSource: ref.watch(userProfileLocalDataSourceProvider),
  );
}

@riverpod
GetUserProfile getUserProfileUseCase(final Ref ref) {
  return GetUserProfile(ref.watch(userProfileRepositoryProvider));
}

@riverpod
UpdateUserAvatar updateUserAvatarUseCase(final Ref ref) {
  return UpdateUserAvatar(ref.watch(userProfileRepositoryProvider));
}

@riverpod
UpdateUserBodyMeasurements updateUserBodyMeasurementsUseCase(final Ref ref) {
  return UpdateUserBodyMeasurements(ref.watch(userProfileRepositoryProvider));
}

@riverpod
UpdateUserProfile updateUserProfileUseCase(final Ref ref) {
  return UpdateUserProfile(ref.watch(userProfileRepositoryProvider));
}

@riverpod
UpdateStylePreferences updateStylePreferencesUseCase(final Ref ref) {
  return UpdateStylePreferences(ref.watch(userProfileRepositoryProvider));
}

@riverpod
Future<UserProfile?> userProfile(final Ref ref) async {
  final isLoggedIn = ref.watch(isAuthenticatedProvider);
  if (!isLoggedIn) return null;

  final getUserProfileUseCase = ref.watch(getUserProfileUseCaseProvider);
  final result = await getUserProfileUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
Future<File?> avatarFile(final Ref ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null || profile.avatarPath == null || profile.avatarPath!.isEmpty) {
    return null;
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  final result = await repository.getUserAvatar(profile.avatarPath!);

  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get();
}

/// 強制刷新用戶資料和頭像
Future<void> refreshUserProfile(final WidgetRef ref) async {
  final getUserProfileUseCase = ref.read(getUserProfileUseCaseProvider);
  await getUserProfileUseCase(forceRefresh: true);
  try {
    ref.invalidate(userProfileProvider);
    await ref.read(userProfileProvider.future);
    await ref.read(avatarFileProvider.future);
  } catch (_) {
    // Provider 刷新失敗時（例如網絡錯誤），忽略異常
    // Provider 會自動進入 error 狀態，UI 會顯示 ErrorView 或舊資料
  }
}
