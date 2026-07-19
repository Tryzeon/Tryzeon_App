import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';
import 'package:tryzeon/feature/personal/shop/domain/extensions/user_gender_extension.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_filter_provider.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';

import '../sheets/filter_sheet.dart';
import '../widgets/ad_banner.dart';
import '../widgets/product_category_filter.dart';
import '../widgets/product_grid.dart';
import '../widgets/search_bar.dart';
import '../widgets/shop_gender_filter.dart';

class ShopPage extends HookConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final adsAsync = ref.watch(shopAdsProvider);

    // 篩選/排序狀態
    final filterState = ref.watch(shopFilterProvider);
    final filterNotifier = ref.read(shopFilterProvider.notifier);
    final isLocating = useState(false);

    // 進入頁面時，性別篩選預設為使用者個人資料的性別；若沒有設定性別，
    // 則預設為第一個選項（女裝）。（只設定一次）
    final profileGender = userProfile?.gender;
    useEffect(() {
      if (ref.read(shopFilterProvider).gender == null) {
        Future.microtask(() {
          if (!context.mounted) return;
          filterNotifier.setGender(
            profileGender?.toProductGender() ?? ProductGender.female,
          );
        });
      }
      return null;
    }, [profileGender]);

    // 類別清單跟著性別篩選走（男裝/女裝）：顯示適用該性別的類別。
    final selectedGender = filterState.gender;
    final productCategoriesAsync = ref
        .watch(productCategoriesProvider)
        .whenData(
          (final list) => selectedGender == null
              ? const <ProductCategory>[]
              : list.where((final c) => c.appliesTo(selectedGender)).toList(),
        );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleSortByLatest() {
      filterNotifier.setSort(const ShopSort.latest());
    }

    void handleSortByPrice() {
      final next = filterState.sort is ShopSortPriceLowToHigh
          ? const ShopSort.priceHighToLow()
          : const ShopSort.priceLowToHigh();
      filterNotifier.setSort(next);
    }

    Future<void> handleSortByProximity() async {
      if (isLocating.value) return;
      isLocating.value = true;
      try {
        final locationService = ref.read(locationServiceProvider);
        final permission = await locationService.requestPermission();
        if (!context.mounted) return;

        if (permission == LocationPermission.denied) {
          TopNotification.show(context, message: '需開啟定位才能依距離排序');
          return;
        }
        if (permission == LocationPermission.deniedForever) {
          final result = await showAppOkCancelDialog(
            context: context,
            title: '需要定位權限',
            message: '為了依距離排序店家，我們需要您的位置權限。請前往設定開啟權限。',
            okLabel: '前往設定',
            cancelLabel: '取消',
          );
          if (result == OkCancelResult.ok) {
            await Geolocator.openAppSettings();
          }
          return;
        }

        final coords = await locationService.getCoordinates();
        if (!context.mounted) return;
        if (coords == null) {
          TopNotification.show(context, message: '無法取得目前位置，請稍後再試');
          return;
        }
        filterNotifier.setSort(
          ShopSort.proximity(latitude: coords.latitude, longitude: coords.longitude),
        );
      } finally {
        if (context.mounted) isLocating.value = false;
      }
    }

    void handleShowFilterSheet() {
      FilterSheet.show(context: context);
    }

    Widget buildSortButton({
      required final String label,
      required final IconData icon,
      required final bool isActive,
      required final VoidCallback onTap,
      final bool isLoading = false,
    }) {
      return ChoiceChip(
        label: Text(label),
        avatar: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
              )
            : Icon(icon, size: 16),
        selected: isActive,
        onSelected: isLoading ? null : (_) => onTap(),
        showCheckmark: false,
      );
    }

    Widget buildComprehensiveSortButton() {
      final isActive = filterState.sort is ShopSortLatest;
      return buildSortButton(
        label: '綜合',
        icon: Icons.emoji_events_outlined,
        isActive: isActive,
        onTap: handleSortByLatest,
      );
    }

    Widget buildPriceSortButton() {
      final isActive =
          filterState.sort is ShopSortPriceLowToHigh ||
          filterState.sort is ShopSortPriceHighToLow;
      final isAscending = filterState.sort is ShopSortPriceLowToHigh;

      return buildSortButton(
        label: '價格',
        icon: !isActive || isAscending ? Icons.arrow_upward : Icons.arrow_downward,
        isActive: isActive,
        onTap: handleSortByPrice,
      );
    }

    Widget buildProximitySortButton() {
      final isActive = filterState.sort is ShopSortProximity;
      return buildSortButton(
        label: '附近',
        icon: Icons.near_me_outlined,
        isActive: isActive,
        onTap: handleSortByProximity,
        isLoading: isLocating.value,
      );
    }

    Widget buildFilterButton() {
      final button = IconButton.filledTonal(
        icon: const Icon(Icons.filter_list_rounded, size: 18),
        onPressed: handleShowFilterSheet,
      );
      final count = filterState.activeFilterCount;
      if (count == 0) return button;
      return Badge.count(count: count, child: button);
    }

    final filter = filterState;
    final productsAsync = ref.watch(shopProductsProvider(filter));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 內容區域
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(shopProductsProvider(filter).notifier).refresh(),
                child: LayoutBuilder(
                  builder: (final context, final constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔍 搜尋欄
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: ShopSearchBar(
                                onSearch: (final query) async {
                                  filterNotifier.setSearch(query);
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.mdLg),

                            // 📢 廣告輪播
                            AdBanner(adsAsync: adsAsync),
                            const SizedBox(height: AppSpacing.lg),

                            // 男女裝篩選
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: ShopGenderFilter(
                                selected: filterState.gender,
                                onChanged: filterNotifier.setGender,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // 商品類型篩選標籤
                            ProductCategoryFilter(
                              categoriesAsync: productCategoriesAsync,
                              selectedCategoryIds: filterState.categories ?? {},
                              gender: selectedGender,
                              onCategoryToggle: (final categoryId) {
                                final current = filterState.categories ?? {};
                                if (current.contains(categoryId)) {
                                  filterNotifier.setCategories(
                                    current.where((final id) => id != categoryId).toSet(),
                                  );
                                } else {
                                  filterNotifier.setCategories({...current, categoryId});
                                }
                              },
                              onRetry: () {
                                // Invalidate upstream provider to refetch from backend
                                ref.invalidate(productCategoriesProvider);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // 推薦商品標題與排序
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECOMMENDED',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.smMd),
                                  Row(
                                    children: [
                                      buildComprehensiveSortButton(),
                                      const SizedBox(width: AppSpacing.sm),
                                      buildPriceSortButton(),
                                      const SizedBox(width: AppSpacing.sm),
                                      buildProximitySortButton(),
                                      const Spacer(),
                                      buildFilterButton(),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // 商品 Grid（可滾動）
                            ProductGrid(
                              productsAsync: productsAsync,
                              userProfile: userProfile,
                              onRetry: () => ref.invalidate(shopProductsProvider(filter)),
                            ),

                            SizedBox(
                              height: PlatformInfo.isIOS26OrHigher()
                                  ? MediaQuery.of(context).padding.bottom +
                                        AppSpacing.iosTabBarHeight
                                  : 0,
                            ),
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
    );
  }
}
