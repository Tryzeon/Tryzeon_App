import 'package:flutter/material.dart';
import 'dart:async';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late List<String> adImages;
  late List<Map<String, String>> partnerBrands;
  late List<String> extendedAdImages;

  late PageController _pageController;
  int _currentPage = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // 初始化資料（未來可改為 API 載入）
    adImages = [
      'assets/images/ads/gu.jpg',
      'assets/images/ads/net.png',
      'assets/images/ads/zara.jpg',
    ];

    partnerBrands = [
      {"name": "品牌一", "image": "assets/images/ads/gu.jpg"},
      {"name": "品牌二", "image": "assets/images/ads/gu.jpg"},
      {"name": "品牌三", "image": "assets/images/ads/gu.jpg"},
      {"name": "品牌四", "image": "assets/images/ads/gu.jpg"},
      {"name": "品牌五", "image": "assets/images/ads/gu.jpg"},
      {"name": "品牌六", "image": "assets/images/ads/gu.jpg"},
    ];

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


  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
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
                  decoration: InputDecoration(
                    hintText: '搜尋品牌或商品',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

              // 🏬 合作品牌 Grid（可滾動）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // 禁止 GridView 自己滾動
                  itemCount: partnerBrands.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final brand = partnerBrands[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  brand['image']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '商品：${brand['productName']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                            Text(
                              '價格：\$${brand['price']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                            Text(
                              '店家：${brand['storeName']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5D4037),
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