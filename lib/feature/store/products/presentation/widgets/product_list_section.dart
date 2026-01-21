import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/dialogs/sort_dialog.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/store/products/providers/providers.dart';

class ProductListSection extends HookConsumerWidget {
  const ProductListSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final sortBy = useState('created_at');
    final ascending = useState(false);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleSortChange(final String newSortBy) {
      sortBy.value = newSortBy;
    }

    void handleAscendingChange(final bool value) {
      ascending.value = value;
    }

    void showSortOptions() {
      SortOptionsDialog(
        context: context,
        sortBy: sortBy.value,
        ascending: ascending.value,
        onSortChange: handleSortChange,
        onAscendingChange: handleAscendingChange,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text('我的商品', style: textTheme.titleLarge),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.sort_rounded, color: colorScheme.primary),
                onPressed: showSortOptions,
                tooltip: '排序',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(productsProvider),
          ),
          data: (final data) {
            final products = data.sortProducts(sortBy.value, ascending.value);

            if (products.isEmpty) {
              return LayoutBuilder(
                builder: (final context, final constraints) {
                  final double minHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 400; // 如果是無限高度，給予一個合理的預設值

                  return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 50,
                              color: colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '還沒有商品',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '點擊右下角按鈕新增商品',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (final context, final index) {
                final product = products[index];
                return StoreProductCard(product: product);
              },
            );
          },
        ),
      ],
    );
  }
}
