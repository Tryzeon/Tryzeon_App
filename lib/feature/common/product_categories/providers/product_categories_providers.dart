import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/repositories/product_category_repository_impl.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/build_category_tree.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/expand_category_ids.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/get_product_categories.dart';
import 'package:typed_result/typed_result.dart';

part 'product_categories_providers.g.dart';

@riverpod
ProductCategoryRemoteDataSource productCategoryRemoteDataSource(final Ref ref) {
  return ProductCategoryRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductCategoryLocalDataSource productCategoryLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return ProductCategoryLocalDataSource(isarService, cacheEntryLocalDataSource);
}

@riverpod
ProductCategoryRepository productCategoryRepository(final Ref ref) {
  return ProductCategoryRepositoryImpl(
    ref.watch(productCategoryRemoteDataSourceProvider),
    ref.watch(productCategoryLocalDataSourceProvider),
  );
}

@riverpod
GetProductCategories getProductCategoriesUseCase(final Ref ref) {
  return GetProductCategories(ref.watch(productCategoryRepositoryProvider));
}

@riverpod
BuildCategoryTree buildCategoryTreeUseCase(final Ref ref) {
  return BuildCategoryTree();
}

@riverpod
ExpandCategoryIds expandCategoryIdsUseCase(final Ref ref) {
  return ExpandCategoryIds();
}

@riverpod
Future<List<ProductCategory>> productCategories(final Ref ref) async {
  final result = await ref.watch(getProductCategoriesUseCaseProvider).call();

  if (result.isSuccess) {
    return result.get()!;
  } else {
    throw result.getError()!;
  }
}

Future<void> refreshProductCategories(final WidgetRef ref) async {
  final useCase = ref.read(getProductCategoriesUseCaseProvider);
  await useCase(forceRefresh: true);
  try {
    ref.invalidate(productCategoriesProvider);
    await ref.read(productCategoriesProvider.future);
  } catch (_) {}
}

@riverpod
Future<List<CategoryTreeNode>> productCategoryTree(final Ref ref) async {
  final categories = await ref.watch(productCategoriesProvider.future);
  final buildTree = ref.watch(buildCategoryTreeUseCaseProvider);
  return buildTree(categories);
}
