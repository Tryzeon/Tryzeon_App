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
  String _sortBy = 'created_at';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final name = await StoreService.getStoreName();
    final productList = await ProductService.getStoreProducts(
      sortBy: _sortBy,
      ascending: _ascending,
    );

    setState(() {
      storeName = name;
      products = productList;
      isLoading = false;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '排序方式',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<String>(
                    groupValue: _sortBy,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          _sortBy = newValue;
                        });
                        setState(() {
                          _sortBy = newValue;
                        });
                        _loadStoreData();
                      }
                    },
                    child: Column(
                      children: [
                        _buildSortOption('價格', 'price'),
                        _buildSortOption('建立時間', 'created_at'),
                        _buildSortOption('更新時間', 'updated_at'),
                        _buildSortOption('試穿次數', 'tryon_count'),
                        _buildSortOption('購買點擊次數', 'purchase_click_count'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('遞增排序'),
                    value: _ascending,
                    onChanged: (value) {
                      setModalState(() {
                        _ascending = value;
                      });
                      setState(() {
                        _ascending = value;
                      });
                      _loadStoreData();
                    },
                  ),
                ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('我的商品',
                          style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.sort),
                        onPressed: _showSortOptions,
                        tooltip: '排序',
                      ),
                    ],
                  ),
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