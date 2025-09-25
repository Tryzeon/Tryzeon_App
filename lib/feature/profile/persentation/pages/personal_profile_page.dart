import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../../login/persentation/pages/login_page.dart';
import '../widget/profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  
  @override
  void initState() {
    super.initState();
    _loadUsername();
  }
  
  void _loadUsername() {
    final displayName = AuthService.displayName;
    setState(() {
      username = displayName;
    });
  }

  void _handleLogout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
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
            Text(
              '您好, $username',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),


            // 基本資料卡片
            Card(
              elevation: 2,
              color: const Color(0xFFF5EBDD),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('基本資料'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileEditPage(),
                    ),
                  );
                  
                  // 果從編輯頁面返回且有更新，重新載入使用者名稱如
                  if (result == true) {
                    _loadUsername();
                  }
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
}

