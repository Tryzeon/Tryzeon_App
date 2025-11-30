import 'package:flutter/material.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/product_service.dart';
import '../dialogs/sort_dialog.dart';
import '../widgets/product_card.dart';
import 'add_product_page.dart';
import 'settings/data/profile_service.dart';
import 'settings/presentation/pages/settings_page.dart';

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  String storeName = '店家';
  List<Product> products = [];
  String _sortBy = 'created_at';
  bool _ascending = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData({final bool forceRefresh = false}) async {
    await _loadStoreName(forceRefresh: forceRefresh);
    await _loadStoreProducts(forceRefresh: forceRefresh);
  }

  Future<void> _loadStoreName({final bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final name = await StoreProfileService.getStoreName(
      forceRefresh: forceRefresh,
    );

    setState(() {
      storeName = name;
      _isLoading = false;
    });
  }

  Future<void> _loadStoreProducts({final bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await ProductService.getProducts(
      sortBy: _sortBy,
      ascending: _ascending,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      setState(() {
        products = result.data!;
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  void _handleSortChange(final String newSortBy) {
    setState(() {
      _sortBy = newSortBy;
    });
    _loadStoreProducts();
  }

  void _handleAscendingChange(final bool value) {
    setState(() {
      _ascending = value;
    });
    _loadStoreProducts();
  }

  void _showSortOptions() {
    SortOptionsDialog(
      context: context,
      sortBy: _sortBy,
      ascending: _ascending,
      onSortChange: _handleSortChange,
      onAscendingChange: _handleAscendingChange,
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
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                        Icons.store_rounded,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('店家後台', style: textTheme.titleLarge),
                          Text(
                            '歡迎回來，$storeName',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.settings_rounded,
                          color: colorScheme.primary,
                        ),
                        onPressed: () async {
                          final hasChanges = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (final context) =>
                                  const StoreSettingsPage(),
                            ),
                          );
                          if (hasChanges == true) {
                            await _loadStoreData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 內容區域
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadStoreData(forceRefresh: true),
                        color: colorScheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // 我的商品標題
                              Row(
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
                                  Text('我的商品', style: textTheme.titleLarge),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.sort_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed: _showSortOptions,
                                      tooltip: '排序',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: products.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                size: 50,
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              '還沒有商品',
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withValues(alpha: 0.6),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '點擊右下角按鈕新增商品',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              childAspectRatio: 0.75,
                                            ),
                                        itemCount: products.length,
                                        itemBuilder:
                                            (final context, final index) {
                                              final product = products[index];
                                              return StoreProductCard(
                                                product: product,
                                                onUpdate: _loadStoreProducts,
                                              );
                                            },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final context) => const AddProductPage(),
                ),
              ).then((final success) {
                if (success == true) {
                  _loadStoreProducts();
                }
              });
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.add_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
