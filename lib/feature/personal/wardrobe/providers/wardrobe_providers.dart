import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/background_remover_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/label_tagger_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/background_remover.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/label_tagger.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/analyze_wardrobe_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_item_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_items.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/update_wardrobe_item_tags.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

part 'wardrobe_providers.g.dart';

@riverpod
WardrobeRemoteDataSource wardrobeRemoteDataSource(final Ref ref) {
  return WardrobeRemoteDataSource(Supabase.instance.client);
}

@riverpod
WardrobeLocalDataSource wardrobeLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return WardrobeLocalDataSource(isarService, cacheService, cacheEntryLocalDataSource);
}

@riverpod
WardrobeRepository wardrobeRepository(final Ref ref) {
  return WardrobeRepositoryImpl(
    remoteDataSource: ref.watch(wardrobeRemoteDataSourceProvider),
    localDataSource: ref.watch(wardrobeLocalDataSourceProvider),
  );
}

@riverpod
GetWardrobeItems getWardrobeItemsUseCase(final Ref ref) {
  return GetWardrobeItems(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
UploadWardrobeItem uploadWardrobeItemUseCase(final Ref ref) {
  return UploadWardrobeItem(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
DeleteWardrobeItem deleteWardrobeItemUseCase(final Ref ref) {
  return DeleteWardrobeItem(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
UpdateWardrobeItemTags updateWardrobeItemTagsUseCase(final Ref ref) {
  return UpdateWardrobeItemTags(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
GetWardrobeItemImage getWardrobeItemImageUseCase(final Ref ref) {
  return GetWardrobeItemImage(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
LabelTagger labelTagger(final Ref ref) => LabelTaggerImpl(Supabase.instance.client);

@riverpod
BackgroundRemover backgroundRemover(final Ref ref) => BackgroundRemoverImpl();

@riverpod
AnalyzeWardrobeImage analyzeWardrobeImageUseCase(final Ref ref) {
  return AnalyzeWardrobeImage(
    labelTagger: ref.watch(labelTaggerProvider),
    backgroundRemover: ref.watch(backgroundRemoverProvider),
  );
}

@riverpod
Future<List<WardrobeItem>> wardrobeItems(final Ref ref) async {
  final getWardrobeItemsUseCase = ref.watch(getWardrobeItemsUseCaseProvider);
  final result = await getWardrobeItemsUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

/// 強制刷新衣櫃列表
Future<void> refreshWardrobeItems(final WidgetRef ref) async {
  final getWardrobeItemsUseCase = ref.read(getWardrobeItemsUseCaseProvider);
  await getWardrobeItemsUseCase(forceRefresh: true);
  try {
    ref.invalidate(wardrobeItemsProvider);
    await ref.read(wardrobeItemsProvider.future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}

@riverpod
Future<File> wardrobeItemImage(final Ref ref, final String imagePath) async {
  final getWardrobeItemImageUseCase = ref.watch(getWardrobeItemImageUseCaseProvider);
  final result = await getWardrobeItemImageUseCase(imagePath);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}
