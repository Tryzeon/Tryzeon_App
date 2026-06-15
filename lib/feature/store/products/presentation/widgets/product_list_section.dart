import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class ProductListSection extends HookConsumerWidget {
  const ProductListSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final query = ref.watch(productQueryProvider);

    // Centers a non-grid state (empty / loading / error) within the available
    // height while staying scrollable so pull-to-refresh keeps working.
    Widget centeredFill(final Widget child) {
      return LayoutBuilder(
        builder: (final context, final constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      );
    }

    Widget buildProductGrid(final List<Product> products) {
      if (products.isEmpty) {
        return centeredFill(_EmptyState(hasQuery: query.searchQuery.isNotEmpty));
      }

      final bottomInset =
          MediaQuery.of(context).padding.bottom +
          80 + // FAB clearance
          (PlatformInfo.isIOS26OrHigher() ? AppSpacing.iosTabBarHeight : 0.0);

      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, bottomInset),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.6,
        ),
        itemCount: products.length,
        itemBuilder: (final context, final index) =>
            StoreProductCard(product: products[index]),
      );
    }

    return filteredProductsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => centeredFill(const CircularProgressIndicator()),
      error: (final error, final stack) => centeredFill(
        ErrorView(
          message: error.displayMessage(context),
          onRetry: () => refreshProducts(ref),
        ),
      ),
      data: buildProductGrid,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 32, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(hasQuery ? '沒有符合條件的商品' : '還沒有商品', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasQuery ? '試試清除搜尋關鍵字' : '點擊右下角按鈕新增商品',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
