import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_item_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_items.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

final wardrobeRemoteDataSourceProvider = Provider<WardrobeRemoteDataSource>((final ref) {
  return WardrobeRemoteDataSource(Supabase.instance.client);
});

final wardrobeLocalDataSourceProvider = Provider<WardrobeLocalDataSource>((final ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return WardrobeLocalDataSource(isarService, cacheService);
});

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((final ref) {
  return WardrobeRepositoryImpl(
    remoteDataSource: ref.watch(wardrobeRemoteDataSourceProvider),
    localDataSource: ref.watch(wardrobeLocalDataSourceProvider),
  );
});

final getWardrobeItemsUseCaseProvider = Provider<GetWardrobeItems>((final ref) {
  return GetWardrobeItems(ref.watch(wardrobeRepositoryProvider));
});

final uploadWardrobeItemUseCaseProvider = Provider<UploadWardrobeItem>((final ref) {
  return UploadWardrobeItem(ref.watch(wardrobeRepositoryProvider));
});

final deleteWardrobeItemUseCaseProvider = Provider<DeleteWardrobeItem>((final ref) {
  return DeleteWardrobeItem(ref.watch(wardrobeRepositoryProvider));
});

final getWardrobeItemImageUseCaseProvider = Provider<GetWardrobeItemImage>((final ref) {
  return GetWardrobeItemImage(ref.watch(wardrobeRepositoryProvider));
});

final wardrobeItemsProvider = FutureProvider.autoDispose<List<WardrobeItem>>((
  final ref,
) async {
  final useCase = ref.watch(getWardrobeItemsUseCaseProvider);
  final result = await useCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

/// 強制刷新衣櫃列表
Future<void> refreshWardrobeItems(final WidgetRef ref) async {
  final useCase = ref.read(getWardrobeItemsUseCaseProvider);
  await useCase(forceRefresh: true);
  try {
    final _ = await ref.refresh(wardrobeItemsProvider.future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}

final wardrobeItemImageProvider = FutureProvider.family.autoDispose<File, String>((
  final ref,
  final imagePath,
) async {
  final useCase = ref.watch(getWardrobeItemImageUseCaseProvider);
  final result = await useCase(imagePath);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});
