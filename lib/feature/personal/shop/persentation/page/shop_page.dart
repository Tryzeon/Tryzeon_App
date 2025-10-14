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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '篩選與排序',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),

                    // 排序選項
                    Text(
                      '排序方式',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
                          _buildSortOption('價格', 'price'),
                          _buildSortOption('建立時間', 'created_at'),
                          _buildSortOption('更新時間', 'updated_at'),
                          _buildSortOption('試穿次數', 'tryon_count'),
                        ],
                      ),
                    ),

                    SwitchListTile(
                      title: const Text('遞增排序'),
                      value: _ascending,
                      onChanged: (value) {
                        setModalState(() {
                          _ascending = value;
                        });
                      },
                    ),

                    const Divider(height: 32),

                    // 價格區間
                    Text(
                      '價格區間',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '最低價格',
                              border: OutlineInputBorder(),
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
                            decoration: const InputDecoration(
                              labelText: '最高價格',
                              border: OutlineInputBorder(),
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
                          child: OutlinedButton(
                            onPressed: () {
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
                            child: const Text('重置'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // 套用篩選
                              });
                              _loadProducts();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D4037),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('套用'),
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

  Widget _buildSortOption(String label, String value) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: value,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔍 搜尋欄
              ShopSearchBar(
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

              const SizedBox(height: 20),

              // 📢 廣告輪播
              AdBanner(adImages: adImages),

              const SizedBox(height: 24),

              // 推薦商品標題 + 篩選按鈕
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '推薦商品',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                      tooltip: '篩選與排序',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 商品 Grid（可滾動）
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (displayedProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('目前沒有商品'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // 禁止 GridView 自己滾動
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

              const SizedBox(height: 32), // 頁尾空間
            ],
          ),
        ),
      ),
    );
  }
}