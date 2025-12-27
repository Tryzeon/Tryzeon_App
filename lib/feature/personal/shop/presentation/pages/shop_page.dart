import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/personal/presentation/pages/settings/data/profile_service.dart';
import 'package:tryzeon/feature/personal/shop/data/ad_service.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/services/product_type_service.dart';
import 'package:tryzeon/shared/widgets/app_query_builder.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:typed_result/typed_result.dart';

import '../../data/shop_service.dart';
import '../dialogs/filter_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/type_filter.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<String> adImages = [];
  List<Product> displayedProducts = [];
  bool isLoading = true;
  UserProfile? _userProfile;

  // 過濾和排序狀態
  String _sortBy = 'tryon_count';
  bool _ascending = false;
  int? _minPrice;
  int? _maxPrice;
  String? _searchQuery;

  // 商品類型列表
  final Set<String> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    _loadAdImages();
    _loadProducts();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final state = await UserProfileService.userProfileQuery().fetch();
    if (!mounted) return;
    setState(() {
      _userProfile = state.data;
    });
  }

  Future<void> _loadAdImages({final bool forceRefresh = false}) async {
    final response = await AdService.getAdImages(forceRefresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      adImages = response;
    });
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    final result = await ShopService.getProducts(
      searchQuery: _searchQuery,
      sortBy: _sortBy,
      ascending: _ascending,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      types: _selectedTypes.isEmpty ? null : _selectedTypes,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        displayedProducts = result.get()!;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      TopNotification.show(
        context,
        message: result.getError()!,
        type: NotificationType.error,
      );
    }
  }

  void _handleSortByTryonCount() {
    if (_sortBy == 'tryon_count') return;
    setState(() {
      _sortBy = 'tryon_count';
      _ascending = false;
    });
    _loadProducts();
  }

  void _handleSortByPrice() {
    setState(() {
      _sortBy = 'price';
      _ascending = !_ascending;
    });
    _loadProducts();
  }

  void _handleShowFilterDialog() {
    FilterDialog(
      context: context,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      onApply: (final minPrice, final maxPrice) {
        setState(() {
          _minPrice = minPrice;
          _maxPrice = maxPrice;
        });
        _loadProducts();
      },
    );
  }

  Widget _buildComprehensiveSortButton() {
    final isActive = _sortBy != 'price';
    return _buildSortButton(
      label: '綜合',
      icon: Icons.emoji_events_outlined,
      isActive: isActive,
      onTap: _handleSortByTryonCount,
    );
  }

  Widget _buildPriceSortButton() {
    final isActive = _sortBy == 'price';
    return _buildSortButton(
      label: '價格',
      icon: _ascending ? Icons.arrow_upward : Icons.arrow_downward,
      isActive: isActive,
      onTap: _handleSortByPrice,
    );
  }

  Widget _buildSortButton({
    required final String label,
    required final IconData icon,
    required final bool isActive,
    required final VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

  Widget _buildFilterButton() {
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
          onTap: _handleShowFilterDialog,
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

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  onRefresh: _loadProducts,
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔍 搜尋欄
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ShopSearchBar(
                            onSearch: (final query) {
                              setState(() => _searchQuery = query.isEmpty ? null : query);
                              return _loadProducts();
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 📢 廣告輪播
                        AdBanner(adImages: adImages),

                        const SizedBox(height: 24),

                        // 商品類型篩選標籤
                        AppQueryBuilder<List<String>>(
                          query: ProductTypeService.productTypesQuery(),
                          isCompact: true,
                          builder: (final context, final types) {
                            return ProductTypeFilter(
                              productTypes: types,
                              selectedTypes: _selectedTypes,
                              onTypeToggle: (final type) {
                                setState(
                                  () => _selectedTypes.contains(type)
                                      ? _selectedTypes.remove(type)
                                      : _selectedTypes.add(type),
                                );
                                _loadProducts();
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
                                    colors: [colorScheme.primary, colorScheme.secondary],
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
                                  _buildComprehensiveSortButton(),
                                  const SizedBox(width: 8),
                                  _buildPriceSortButton(),
                                  const SizedBox(width: 8),
                                  _buildFilterButton(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 商品 Grid（可滾動）
                        if (isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48.0),
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        else if (displayedProducts.isEmpty)
                          Center(
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
                          )
                        else
                          Padding(
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
                                  userProfile: _userProfile,
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
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
