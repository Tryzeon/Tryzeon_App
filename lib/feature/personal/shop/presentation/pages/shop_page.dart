import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/settings/data/profile_service.dart';
import 'package:tryzeon/feature/personal/shop/data/ad_service.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/services/product_type_service.dart';
import 'package:tryzeon/shared/widgets/app_query_builder.dart';

import '../../data/shop_service.dart';
import '../dialogs/filter_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/type_filter.dart';

class ShopPage extends HookConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final adImages = useState<List<String>>([]);
    final userProfile = useState<UserProfile?>(null);

    // 過濾和排序狀態
    final sortBy = useState('tryon_count');
    final ascending = useState(false);
    final minPrice = useState<int?>(null);
    final maxPrice = useState<int?>(null);
    final searchQuery = useState<String?>(null);

    // 商品類型列表
    final selectedTypes = useState<Set<String>>({});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> loadUserProfile() async {
      final state = await UserProfileService.userProfileQuery().fetch();
      if (!context.mounted) return;
      userProfile.value = state.data;
    }

    Future<void> loadAdImages({final bool forceRefresh = false}) async {
      final response = await AdService.getAdImages(forceRefresh: forceRefresh);
      if (!context.mounted) return;
      adImages.value = response;
    }

    useEffect(() {
      loadAdImages();
      loadUserProfile();
      return null;
    }, []);

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

    final productsQuery = ShopService.productsQuery(
      searchQuery: searchQuery.value,
      sortBy: sortBy.value,
      ascending: ascending.value,
      minPrice: minPrice.value,
      maxPrice: maxPrice.value,
      types: selectedTypes.value,
    );

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
                  onRefresh: productsQuery.fetch,
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
                              AdBanner(adImages: adImages.value),

                              const SizedBox(height: 24),

                              // 商品類型篩選標籤
                              AppQueryBuilder<List<String>>(
                                query: ProductTypeService.productTypesQuery(),
                                isCompact: true,
                                builder: (final context, final types) {
                                  return ProductTypeFilter(
                                    productTypes: types,
                                    selectedTypes: selectedTypes.value,
                                    onTypeToggle: (final type) {
                                      if (selectedTypes.value.contains(type)) {
                                        selectedTypes.value = selectedTypes.value
                                            .where((final t) => t != type)
                                            .toSet();
                                      } else {
                                        selectedTypes.value = {
                                          ...selectedTypes.value,
                                          type,
                                        };
                                      }
                                    },
                                  );
                                },
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
                              AppQueryBuilder<List<Product>>(
                                query: productsQuery,
                                builder: (final context, final displayedProducts) {
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
                                          userProfile: userProfile.value,
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
