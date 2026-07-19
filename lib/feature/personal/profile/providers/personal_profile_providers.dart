import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
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
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    if (!isLoggedIn) return null;

    final getUserProfileUseCase = ref.watch(getUserProfileUseCaseProvider);
    final result = await getUserProfileUseCase();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<void> refresh() async {
    await ref.read(getUserProfileUseCaseProvider)(forceRefresh: true);
    ref.invalidateSelf();
    try {
      await future;
      await ref.read(avatarFileProvider.future);
    } catch (e, st) {
      AppLogger.warning('Failed to refresh user profile', e, st);
    }
  }
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


@riverpod
class AvatarUploadNotifier extends _$AvatarUploadNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<void, Failure>> upload(final File image) async {
    state = const AsyncLoading();
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) {
        state = const AsyncData(null);
        return const Ok(null);
      }

      final result = await ref.read(updateUserAvatarUseCaseProvider)(
        avatarFile: image,
        previousAvatarPath: profile.avatarPath,
      );

      if (result.isSuccess) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(avatarFileProvider);
        await ref.read(avatarFileProvider.future);
      }
      state = result.isFailure
          ? AsyncError(result.getError()!, StackTrace.current)
          : const AsyncData(null);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload avatar', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
