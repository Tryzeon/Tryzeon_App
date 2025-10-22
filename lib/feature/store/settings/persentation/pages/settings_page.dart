import 'package:flutter/material.dart';
import '../widget/account_settings_page.dart';
import 'package:tryzeon/shared/services/auth_service.dart';
import 'package:tryzeon/shared/component/confirmation_dialog.dart';
import 'package:tryzeon/shared/component/top_notification.dart';
import '../../../../login/persentation/pages/login_page.dart';
import '../../../../personal/personal_entry.dart';

class StoreSettingsPage extends StatelessWidget {
  const StoreSettingsPage({super.key});

  Future<void> _switchToPersonal(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      content: '你確定要切換到個人版帳號嗎？',
    );

    if (confirmed != true) return;

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PersonalEntry()),
        (route) => false,
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final comfirmed = await ConfirmationDialog.show(
      context: context,
      content: '你確定要登出嗎？',
      confirmText: '登出',
    );

    if (comfirmed == true) {
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
              // 自訂 AppBar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '設定',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '管理您的店家帳號',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 內容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // 帳號設定卡片
                      _buildMenuCard(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        title: '帳號設定',
                        subtitle: '管理店家資訊、Logo',
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoreAccountSettingsPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // 切換到個人帳號卡片
                      _buildMenuCard(
                        context: context,
                        icon: Icons.swap_horiz_rounded,
                        title: '切換到個人帳號',
                        subtitle: '切換回個人版本',
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        onTap: () => _switchToPersonal(context),
                      ),

                      const Spacer(),

                      // 登出按鈕
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _signOut(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '登出',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
