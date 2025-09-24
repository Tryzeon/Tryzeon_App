import 'package:flutter/material.dart';

import '../login/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = 'Ingrid';

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人設定'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用者名稱區塊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '您好, $username',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    _showEditUsernameDialog(context);
                  },
                ),
              ],
            ),


            // 基本資料卡片
            Card(
              elevation: 2,
              color: const Color(0xFFF5EBDD),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('基本資料'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to profile info page
                },
              ),
            ),
            const SizedBox(height: 12),

            // 登出
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.brown),
                label: const Text('登出', style: TextStyle(color: Colors.brown)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('確認登出'),
                        content: const Text('您確定要登出嗎？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(); // 關閉 Dialog
                              _handleLogout(); // 執行登出跳轉
                            },
                            child: const Text('確認'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
  void _showEditUsernameDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('編輯使用者名稱'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '輸入新名稱',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    username = newName;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
  }
}

