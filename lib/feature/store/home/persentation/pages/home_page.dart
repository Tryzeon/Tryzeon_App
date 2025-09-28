import 'package:flutter/material.dart';

import '../widget/product_page.dart';
import '../widget/profile_edit_page.dart';
import '../../data/store_info_service.dart';


class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  String storeName = '店家';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final name = await StoreService.getStoreName();
    setState(() {
      storeName = name;
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
          );
        },
        backgroundColor: const Color(0xFF5D4037),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}