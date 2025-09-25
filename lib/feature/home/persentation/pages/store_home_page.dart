import 'package:flutter/material.dart';

import '../../../store/persentation/pages/ProductPage.dart';
import '../../../profile/persentation/pages/store_profile_page.dart';


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
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 導向訂單管理頁
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('訂單管理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoreAccountPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('帳號設定'),
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