import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/providers.dart';
import 'package:tryzeon/feature/store/profile/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../auth/presentation/pages/login_page.dart';
import '../../../../personal/main/personal_entry.dart';

class StoreOnboardingPage extends HookConsumerWidget {
  const StoreOnboardingPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const String formUrl =
        'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';

    Future<void> openForm() async {
      final uri = Uri.parse(formUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        TopNotification.show(context, message: '無法開啟表單連結', type: NotificationType.error);
      }
    }

    Future<void> switchToPersonalAccount() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '切換帳號',
        content: '你確定要切換到個人版帳號嗎？',
      );

      if (confirmed == true) {
        final setLoginTypeUseCase = await ref.read(
          setLastLoginTypeUseCaseProvider.future,
        );
        await setLoginTypeUseCase(UserType.personal);

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (final context) => const PersonalEntry()),
            (final route) => false,
          );
        }
      }
    }

    Future<void> handleLogout() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '登出',
        content: '你確定要登出嗎？',
        confirmText: '登出',
      );

      if (confirmed == true) {
        final signOutUseCase = await ref.read(signOutUseCaseProvider.future);
        await signOutUseCase();
        if (!context.mounted) return;
        // 登出後會自動回到登入頁面（main.dart 會處理）
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (final context) => const LoginPage()),
          (final route) => false,
        );
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題欄
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('店家註冊', style: textTheme.headlineMedium),
                          Text('開始您的店家之旅', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.person_rounded, color: colorScheme.primary),
                        onPressed: switchToPersonalAccount,
                        tooltip: '切換回個人帳號',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.logout_rounded, color: colorScheme.primary),
                        onPressed: handleLogout,
                        tooltip: '登出',
                      ),
                    ),
                  ],
                ),
              ),

              // 內容區域
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.refresh(storeProfileProvider.future),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // 標題圖示
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.edit_document,
                                    color: colorScheme.onPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '立即加入店家清單',
                                  style: textTheme.headlineLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // 開啟表單按鈕
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: openForm,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.open_in_new_rounded,
                                              color: colorScheme.onPrimary,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '開啟申請表單',
                                              style: textTheme.titleSmall?.copyWith(
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.error.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_rounded,
                                        color: colorScheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '必須使用相同 Gmail',
                                        style: textTheme.labelMedium?.copyWith(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 審核時間資訊卡片
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.info_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('審核時間', style: textTheme.titleMedium),
                                      const SizedBox(height: 4),
                                      Text(
                                        '填寫完表單後，請稍等 7-14 個工作天進行審核',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
