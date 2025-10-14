import 'dart:io';
import 'package:flutter/material.dart';
import '../widget/add_product_page.dart';
import '../../../settings/persentation/pages/settings_page.dart';
import '../widget/product_detail_dialog.dart';
import '../../../data/store_service.dart';
import '../../../data/product_service.dart';
import 'package:tryzeon/shared/models/product_model.dart';


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
                  builder: (context) => const StoreSettingsPage(),
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
                              return GestureDetector(
                                onTap: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => ProductDetailDialog(product: product),
                                  );
                                  if (result == true) {
                                    _loadStoreData();
                                  }
                                },
                                child: Card(
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
                                            top: Radius.circular(10),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          child: FutureBuilder<File?>(
                                            future: ProductService.getProductImage(product.imagePath),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData && snapshot.data != null) {
                                                return Image.file(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.image_not_supported),
                                                );
                                              }
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                          ),
                                        )
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
              builder: (context) => const AddProductPage(),
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