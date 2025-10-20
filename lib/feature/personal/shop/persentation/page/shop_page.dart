import 'package:flutter/material.dart';
import '../../data/shop_service.dart';
import '../widget/ad_banner.dart';
import '../widget/search_bar.dart';
import '../widget/product_card.dart';

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
  String _sortBy = 'created_at';
  bool _ascending = false;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();

    // 初始化資料（未來可改為 API 載入）
    adImages = [
      'assets/images/ads/gu.jpg',
      'assets/images/ads/net.png',
      'assets/images/ads/zara.jpg',
    ];

    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    final fetchedProducts = await ShopService.getAllProducts(
      sortBy: _sortBy,
      ascending: _ascending,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );

    setState(() {
      products = fetchedProducts;
      displayedProducts = fetchedProducts;
      isLoading = false;
    });
  }


  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題
                    Row(
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
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '篩選與排序',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 排序選項
                    const Text(
                      '排序方式',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<String>(
                      groupValue: _sortBy,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            _sortBy = newValue;
                          });
                        }
                      },
                      child: Column(
                        children: [
                          _buildSortOption('價格', 'price', setModalState),
                          _buildSortOption('建立時間', 'created_at', setModalState),
                          _buildSortOption('更新時間', 'updated_at', setModalState),
                          _buildSortOption('試穿次數', 'tryon_count', setModalState),
                        ],
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          '遞增排序',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        value: _ascending,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        onChanged: (value) {
                          setModalState(() {
                            _ascending = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 價格區間
                    const Text(
                      '價格區間',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: '最低價格',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              prefixText: '\$',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: _minPrice?.toString() ?? '',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                _minPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: '最高價格',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              prefixText: '\$',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: _maxPrice?.toString() ?? '',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                _maxPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 按鈕
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    _sortBy = 'created_at';
                                    _ascending = false;
                                    _minPrice = null;
                                    _maxPrice = null;
                                  });
                                  setState(() {
                                    _sortBy = 'created_at';
                                    _ascending = false;
                                    _minPrice = null;
                                    _maxPrice = null;
                                  });
                                  _loadProducts();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    '重置',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    // 套用篩選
                                  });
                                  _loadProducts();
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: const Center(
                                  child: Text(
                                    '套用',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
          ),
        ),
        leading: Radio<String>(
          value: value,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary;
            }
            return null;
          }),
        ),
      ),
    );
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
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: _showFilterDialog,
                        tooltip: '篩選與排序',
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
                            setState(() {
                              displayedProducts = results;
                              isLoading = false;
                            });
                          },
                          onSearchStart: () {
                            setState(() {
                              isLoading = true;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📢 廣告輪播
                      AdBanner(adImages: adImages),

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
                                  '目前沒有商品',
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