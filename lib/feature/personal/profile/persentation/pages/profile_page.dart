import 'package:flutter/material.dart';
import 'package:tryzeon/feature/login/persentation/pages/login_page.dart';
import 'package:tryzeon/shared/services/auth_service.dart';
import 'package:tryzeon/shared/services/account_service.dart';
import 'package:tryzeon/feature/store/store_entry.dart';
import 'package:tryzeon/shared/component/confirmation_dialog.dart';
import 'package:tryzeon/shared/component/top_notification.dart';
import '../widget/account_page.dart';


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
    final confirmed = await ConfirmationDialog.show(
      context: context,
      content: '你確定要切換到店家版帳號嗎？',
    );

    if (confirmed != true) return;

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
          MaterialPageRoute(builder: (context) => const StoreEntry()),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題區
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 登出按鈕（右上角）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final confirmed = await ConfirmationDialog.show(
                                  context: context,
                                  content: '你確定要登出嗎？',
                                  confirmText: '登出',
                                );

                                if (confirmed == true) {
                                  _handleLogout();
                                }
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Icon(
                                Icons.logout_rounded,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 頭像
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 使用者名稱
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        '您好, $username',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 功能列表
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // 基本資料卡片
                      _buildMenuCard(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        title: '基本資料',
                        subtitle: '編輯您的個人資訊',
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileEditPage(),
                            ),
                          );

                          if (result == true) {
                            _loadUsername();
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 切換到店家帳號
                      _buildMenuCard(
                        context: context,
                        icon: Icons.store_outlined,
                        title: '切換到店家帳號',
                        subtitle: '管理您的商店',
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        onTap: _switchToStore,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

