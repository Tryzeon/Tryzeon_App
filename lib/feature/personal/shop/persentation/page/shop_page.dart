import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../data/shop_service.dart';
import 'package:tryzeon/shared/data/models/product_model.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late List<String> adImages;
  late List<String> extendedAdImages;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  late PageController _pageController;
  int _currentPage = 1;
  Timer? _timer;
  String? _currentSearchQuery;

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

    extendedAdImages = [
      adImages.last,       // 最前面加最後一張
      ...adImages,
      adImages.first       // 最後面加第一張
    ];


    _pageController = PageController(initialPage: _currentPage);

    // 自動輪播邏輯
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      _currentPage++;

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // 無縫跳轉：滑到尾端複製頁時，瞬間跳回真正的第一頁
      if (_currentPage == extendedAdImages.length - 1) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _pageController.jumpToPage(1);
          _currentPage = 1;
        });
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    final fetchedProducts = await ShopService.getAllProducts();
    
    setState(() {
      products = fetchedProducts;
      displayedProducts = fetchedProducts;
      isLoading = false;
    });
  }

  void _searchProducts(String query) async {
    // 儲存當前的搜尋查詢
    _currentSearchQuery = query;
    
    if (query.trim().isEmpty) {
      setState(() {
        displayedProducts = products;
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    // 儲存當前查詢的參考，用於檢查是否為最新的搜尋
    final currentQuery = query;
    
    final searchResults = await ShopService.searchProducts(query);
    
    // 只有當這是最新的搜尋請求時才更新結果
    if (currentQuery == _currentSearchQuery) {
      setState(() {
        displayedProducts = searchResults;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Widget buildAdBanner() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: extendedAdImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: 點擊廣告導向詳情頁或外部連結
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(extendedAdImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋品牌或商品',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              _searchProducts('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _searchProducts,
                ),
              ),

              const SizedBox(height: 20),

              // 📢 廣告輪播
              buildAdBanner(),

              const SizedBox(height: 24),

              // 🏬 合作品牌 Grid 標題
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '推薦商品',
                  style: Theme.of(context).textTheme.titleLarge,
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
                      final product = productData['product'] as Product;
                      final storeName = productData['storeName'] as String;
                      
                      return GestureDetector(
                        onTap: () async {
                          if (product.purchaseLink.isNotEmpty) {
                            final Uri url = Uri.parse(product.purchaseLink);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('無法開啟購買連結')),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('此商品尚無購買連結')),
                            );
                          }
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: product.imageUrl.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.image_not_supported),
                                              ),
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${product.price}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF5D4037),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      storeName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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