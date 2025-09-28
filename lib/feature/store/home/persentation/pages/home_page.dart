import 'package:flutter/material.dart';

import '../widget/product_page.dart';
import '../widget/profile_edit_page.dart';
import '../../data/store_info_service.dart';
import '../../data/product_service.dart';
import '../../data/product_model.dart';


class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  String storeName = '店家';
  bool isLoading = true;
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final name = await StoreService.getStoreName();
    final productList = await ProductService.getStoreProducts();
    setState(() {
      storeName = name;
      products = productList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('店家後台'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoreAccountPage(),
                ),
              ).then((_) {
                // 當從設定頁面返回時，重新載入店家資料
                _loadStoreData();
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('歡迎回來，$storeName !',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  Text('我的商品',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Text('還沒有商品，點擊右下角新增'),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Card(
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD7CCC8),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(4),
                                          ),
                                        ),
                                        child: product.imageUrl != null
                                            ? ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(4),
                                                ),
                                                child: Image.network(
                                                  product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.image_not_supported),
                                                ),
                                              )
                                            : const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product.type,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFF5D4037),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductSPage(),
            ),
          ).then((_) {
            // 當從商品頁面返回時，重新載入商品資料
            _loadStoreData();
          });
        },
        backgroundColor: const Color(0xFF5D4037),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}