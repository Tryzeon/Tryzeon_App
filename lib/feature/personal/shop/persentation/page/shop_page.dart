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

    final fetchedProducts = await ShopService.getAllProducts();
    
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