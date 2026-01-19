import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/common/product_categories/providers/providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/providers/providers.dart';

import '../dialogs/filter_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/category_filter.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';

class ShopPage extends HookConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productCategoriesAsync = ref.watch(productCategoriesProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final adsAsync = ref.watch(shopAdsProvider);

    // 過濾和排序狀態
    final sortBy = useState('tryon_count');
    final ascending = useState(false);
    final minPrice = useState<int?>(null);
    final maxPrice = useState<int?>(null);
    final searchQuery = useState<String?>(null);

    // 商品類型列表
    final selectedCategories = useState<Set<String>>({});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleSortByTryonCount() {
      if (sortBy.value == 'tryon_count') return;
      sortBy.value = 'tryon_count';
      ascending.value = false;
    }

    void handleSortByPrice() {
      sortBy.value = 'price';
      ascending.value = !ascending.value;
    }

    void handleShowFilterDialog() {
      FilterDialog(
        context: context,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        onApply: (final newMin, final newMax) {
          minPrice.value = newMin;
          maxPrice.value = newMax;
        },
      );
    }

    Widget buildSortButton({
      required final String label,
      required final IconData icon,
      required final bool isActive,
      required final VoidCallback onTap,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? colorScheme.onPrimary : colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: isActive ? colorScheme.onPrimary : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildComprehensiveSortButton() {
      final isActive = sortBy.value != 'price';
      return buildSortButton(
        label: '綜合',
        icon: Icons.emoji_events_outlined,
        isActive: isActive,
        onTap: handleSortByTryonCount,
      );
    }

    Widget buildPriceSortButton() {
      final isActive = sortBy.value == 'price';
      return buildSortButton(
        label: '價格',
        icon: ascending.value ? Icons.arrow_upward : Icons.arrow_downward,
        isActive: isActive,
        onTap: handleSortByPrice,
      );
    }

    Widget buildFilterButton() {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: handleShowFilterDialog,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.filter_list_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
        ),
      );
    }

    final filter = ShopFilter(
      searchQuery: searchQuery.value,
      sortBy: sortBy.value,
      ascending: ascending.value,
      minPrice: minPrice.value,
      maxPrice: maxPrice.value,
      types: selectedCategories.value,
    );

    final productsAsync = ref.watch(shopProductsProvider(filter));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.02),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題欄
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '試衣間',
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '發現時尚新品',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 內容區域
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.refresh(shopProductsProvider(filter).future),
                  color: colorScheme.primary,
                  child: LayoutBuilder(
                    builder: (final context, final constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔍 搜尋欄
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ShopSearchBar(
                                  onSearch: (final query) async {
                                    searchQuery.value = query.isEmpty ? null : query;
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 📢 廣告輪播
                              adsAsync.when(
                                data: (final ads) => AdBanner(adImages: ads),
                                loading: () => const SizedBox(
                                  height: 150,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                error: (final e, final s) => const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 24),

                              // 商品類型篩選標籤
                              productCategoriesAsync.when(
                                data: (final categories) {
                                  return ProductCategoryFilter(
                                    productCategories: categories,
                                    selectedCategories: selectedCategories.value,
                                    onCategoryToggle: (final category) {
                                      if (selectedCategories.value.contains(category)) {
                                        selectedCategories.value = selectedCategories
                                            .value
                                            .where((final t) => t != category)
                                            .toSet();
                                      } else {
                                        selectedCategories.value = {
                                          ...selectedCategories.value,
                                          category,
                                        };
                                      }
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (final error, final stack) => ErrorView(
                                  onRetry: () => ref.refresh(productCategoriesProvider),
                                  isCompact: true,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // 推薦商品標題
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '推薦商品',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        buildComprehensiveSortButton(),
                                        const SizedBox(width: 8),
                                        buildPriceSortButton(),
                                        const SizedBox(width: 8),
                                        buildFilterButton(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 商品 Grid（可滾動）
                              productsAsync.when(
                                loading: () => Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                ),
                                error: (final error, final stack) => ErrorView(
                                  onRetry: () =>
                                      ref.refresh(shopProductsProvider(filter)),
                                ),
                                data: (final displayedProducts) {
                                  if (displayedProducts.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(48.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 64,
                                              color: colorScheme.outlineVariant,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '目前沒有商品符合搜尋條件',
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontSize: 16,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: displayedProducts.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            childAspectRatio: 0.7,
                                          ),
                                      itemBuilder: (final context, final index) {
                                        final product = displayedProducts[index];
                                        return ProductCard(
                                          product: product,
                                          userProfile: userProfile,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
