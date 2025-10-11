import 'package:flutter/material.dart';
import 'package:tryzeon/feature/login/persentation/pages/login_page.dart';
import 'package:tryzeon/shared/services/logout_service.dart';
import 'package:tryzeon/feature/login/data/auth_service.dart';
import 'package:tryzeon/feature/store/home/persentation/pages/home_page.dart';
import '../widget/account_page.dart';
import '../../data/account_service.dart';


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
    final displayName = AccountService.displayName;
    setState(() {
      username = displayName;
    });
  }

  Future<void> _switchToStore() async {
    // 顯示載入對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // 切換帳號類型
    final result = await AuthService.switchUserType(UserType.store);

    // 關閉載入對話框
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result.success) {
      // 切換成功，導航到店家版主頁
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StoreHomePage()),
          (route) => false,
        );
      }
    } else {
      // 切換失敗，顯示錯誤訊息
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('切換失敗'),
              content: Text(result.errorMessage ?? '無法切換到店家版'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _handleLogout() async {
    await LogoutService.logout();
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
        automaticallyImplyLeading: false,
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

            // 切換到店家帳號
            Card(
              elevation: 2,
              color: const Color(0xFFF5EBDD),
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('切換到店家帳號'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _switchToStore,
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
                        content: const Text('您確定要登出齁 ?'),
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
                            child: const Text('確定，但我會記得回來'),
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

