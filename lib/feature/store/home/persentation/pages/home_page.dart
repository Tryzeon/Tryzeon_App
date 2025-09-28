import 'package:flutter/material.dart';

import '../widget/product_page.dart';
import '../widget/profile_edit_page.dart';


class StoreHomePage extends StatelessWidget {
  final String storeName;

  const StoreHomePage({super.key, this.storeName = '店家'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$storeName 後台'),
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
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('歡迎回來，$storeName！',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // 功能按鈕區塊
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductSPage(storeName: storeName),
                  ),
                );
              },
              icon: const Icon(Icons.inventory),
              label: const Text('商品管理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}