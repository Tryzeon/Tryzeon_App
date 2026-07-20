import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/products/presentation/sheets/product_sort_sheet.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_list_section.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_search_bar.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/store_add_product_fab.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class StoreProductsPage extends HookConsumerWidget {
  const StoreProductsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MY PRODUCTS',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('我的商品', style: textTheme.headlineMedium),
                            const SizedBox(width: AppSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                              child: Text(
                                '${ref.watch(productsProvider.select((final async) => async.value?.length ?? 0))} 件商品',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: TextButton(
                        onPressed: () => ProductSortSheet.show(context),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('排序'),
                            SizedBox(width: AppSpacing.xs),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
              child: ProductSearchBar(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(productsProvider.notifier).refresh(),
                child: const ProductListSection(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const StoreAddProductFab(),
    );
  }
}
