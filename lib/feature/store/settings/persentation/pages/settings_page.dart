import 'package:flutter/material.dart';
import 'account_settings_page.dart';
import '../../../../login/persentation/pages/login_page.dart';
import '../../../../login/data/auth_service.dart';
import '../../../../personal/home/persentation/pages/home_navigator.dart';

class StoreSettingsPage extends StatelessWidget {
  const StoreSettingsPage({super.key});

  Future<void> _switchToPersonal(BuildContext context) async {
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
    final result = await AuthService.switchUserType(UserType.personal);

    // 關閉載入對話框
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (result.success) {
      // 切換成功，導航到個人版主頁
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PersonalHomePage()),
          (route) => false,
        );
      }
    } else {
      // 切換失敗，顯示錯誤訊息
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('切換失敗'),
              content: Text(result.errorMessage ?? '無法切換到個人版'),
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

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認登出'),
          content: const Text('你確定要登出齁?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('確定，但我會記得回來'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await AuthService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // 帳號設定選項
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('帳號設定'),
                  subtitle: const Text('管理店家資訊、Logo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreAccountSettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // 切換到個人帳號
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('切換到個人帳號'),
                  subtitle: const Text('切換到個人帳號'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _switchToPersonal(context),
                ),
                const Divider(height: 1),

                // 未來可以在這裡添加其他設定選項
                // 例如：通知設定、隱私設定等
              ],
            ),
          ),

          // 登出按鈕固定在底部
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                '登出',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
