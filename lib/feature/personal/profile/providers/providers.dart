import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_profile.dart';
import 'package:typed_result/typed_result.dart';

final userProfileRemoteDataSourceProvider = Provider<UserProfileRemoteDataSource>((
  final ref,
) {
  return UserProfileRemoteDataSource(Supabase.instance.client);
});

final userProfileLocalDataSourceProvider = Provider<UserProfileLocalDataSource>((
  final ref,
) {
  final isarService = ref.watch(isarServiceProvider);
  return UserProfileLocalDataSource(isarService);
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((final ref) {
  return UserProfileRepositoryImpl(
    remoteDataSource: ref.watch(userProfileRemoteDataSourceProvider),
    localDataSource: ref.watch(userProfileLocalDataSourceProvider),
  );
});

final getUserProfileUseCaseProvider = Provider<GetUserProfile>((final ref) {
  return GetUserProfile(ref.watch(userProfileRepositoryProvider));
});

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfile>((final ref) {
  return UpdateUserProfile(ref.watch(userProfileRepositoryProvider));
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((final ref) async {
  final getUserProfileUseCase = ref.watch(getUserProfileUseCaseProvider);
  final result = await getUserProfileUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

final avatarFileProvider = FutureProvider.autoDispose<File?>((final ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile.avatarPath == null || profile.avatarPath!.isEmpty) {
    return null;
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  final result = await repository.getUserAvatar(profile.avatarPath!);

  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get();
});

/// 強制刷新用戶資料和頭像，失敗時返回原始資料
Future<void> refreshUserProfile(final WidgetRef ref) async {
  final useCase = ref.read(getUserProfileUseCaseProvider);
  await useCase(forceRefresh: true);
  ref.invalidate(userProfileProvider);
  ref.invalidate(avatarFileProvider);
}
