import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  return WardrobeLocalDataSource();
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

final wardrobeItemsProvider = FutureProvider<List<WardrobeItem>>((final ref) async {
  final useCase = ref.watch(getWardrobeItemsUseCaseProvider);
  final result = await useCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

final wardrobeItemImageProvider = FutureProvider.family<File, String>((
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
