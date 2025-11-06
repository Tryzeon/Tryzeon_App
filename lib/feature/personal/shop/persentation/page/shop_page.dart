import 'package:flutter/material.dart';
import '../../data/shop_service.dart';
import '../../data/product_type_service.dart';
import '../widget/ad_banner.dart';
import '../widget/search_bar.dart';
import '../widget/product_card.dart';
import '../widget/product_type_filter.dart';
import '../widget/filter_dialog.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late List<String> adImages;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;

  // 過濾和排序狀態
  String _sortBy = 'tryon_count';
  bool _ascending = false;
  int? _minPrice;
  int? _maxPrice;
  final Set<String> _selectedTypes = {};

  // 商品類型列表
  List<String> _productTypes = [];

  @override
  void initState() {
    super.initState();

    // 初始化資料（未來可改為 API 載入）
    adImages = [
      'assets/images/ads/gu.jpg',
      'assets/images/ads/net.png',
      'assets/images/ads/zara.jpg',
    ];

    _loadProductTypes();
    _loadProducts();
  }

  Future<void> _loadProductTypes() async {
    final types = await ProductTypeService.getProductTypesList();
    if (mounted) {
      setState(() {
        _productTypes = types;
      });
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final fetchedProducts = await ShopService.getProducts(
      sortBy: _sortBy,
      ascending: _ascending,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      types: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
    );

    if (!mounted) return;

    setState(() {
      products = fetchedProducts;
      displayedProducts = fetchedProducts;
      isLoading = false;
    });
  }


  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                Theme.of(context).colorScheme.surface,
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
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '商店',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '發現時尚新品',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔍 搜尋欄
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ShopSearchBar(
                          products: products,
                          onSearchResults: (results) {
                            if (mounted) {
                              setState(() {
                                displayedProducts = results;
                                isLoading = false;
                              });
                            }
                          },
                          onSearchStart: () {
                            if (mounted) {
                              setState(() {
                                isLoading = true;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📢 廣告輪播
                      AdBanner(adImages: adImages),

                      const SizedBox(height: 24),

                      // 商品類型篩選標籤
                      ProductTypeFilter(
                        productTypes: _productTypes,
                        selectedTypes: _selectedTypes,
                        onTypeToggle: (type) {
                          setState(() {
                            if (_selectedTypes.contains(type)) {
                              _selectedTypes.remove(type);
                            } else {
                              _selectedTypes.add(type);
                            }
                          });
                          _loadProducts();
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
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '推薦商品',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            // 綜合排名按鈕
                            Container(
                              decoration: BoxDecoration(
                                color: _sortBy != 'price'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (_sortBy != 'tryon_count') {
                                      setState(() {
                                        _sortBy = 'tryon_count';
                                        _ascending = false;
                                      });
                                      _loadProducts();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.emoji_events_outlined,
                                          color: _sortBy != 'price'
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '綜合',
                                          style: TextStyle(
                                            color: _sortBy != 'price'
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 價格排序按鈕
                            Container(
                              decoration: BoxDecoration(
                                color: _sortBy == 'price'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _sortBy = 'price';
                                      _ascending = !_ascending;
                                    });
                                    _loadProducts();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _ascending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: _sortBy == 'price'
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '價格',
                                          style: TextStyle(
                                            color: _sortBy == 'price'
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    FilterDialog(
                                      context: context,
                                      minPrice: _minPrice,
                                      maxPrice: _maxPrice,
                                      onApply: (minPrice, maxPrice) {
                                        if (mounted) {
                                          setState(() {
                                            _minPrice = minPrice;
                                            _maxPrice = maxPrice;
                                          });
                                          _loadProducts();
                                        }
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Icon(
                                    Icons.filter_list_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                              ),
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
                              color: Theme.of(context).colorScheme.primary,
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
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '目前沒有商品符合搜尋條件',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                            itemBuilder: (context, index) {
                              final productData = displayedProducts[index];
                              return ProductCard(productData: productData);
                            },
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
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