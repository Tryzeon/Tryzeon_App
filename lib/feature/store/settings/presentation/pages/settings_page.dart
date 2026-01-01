import 'package:flutter/material.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/pages/base_settings_page.dart';

import '../../../../personal/main/personal_entry.dart';
import 'profile_setting_page.dart';

class StoreSettingsPage extends BaseSettingsPage {
  const StoreSettingsPage({super.key});

  @override
  BaseSettingsPageState createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends BaseSettingsPageState<StoreSettingsPage> {
  @override
  List<SettingsMenuItem> buildMenuItems() {
    return [
      SettingsMenuItem(
        icon: Icons.person_outline_rounded,
        title: '店家設定',
        subtitle: '管理店家資訊、Logo',
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        onTap: _navigateToProfile,
      ),
      SettingsMenuItem(
        icon: Icons.swap_horiz_rounded,
        title: '切換到個人帳號',
        subtitle: '切換回個人版本',
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ],
        ),
        onTap: _switchToPersonal,
      ),
    ];
  }

  Future<void> _switchToPersonal() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: '切換帳號',
      content: '你確定要切換到個人版帳號嗎？',
    );

    if (confirmed != true) return;

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const PersonalEntry()),
        (final route) => false,
      );
    }
  }

  Future<void> _navigateToProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (final context) => const StoreProfileSettingsPage()),
    );
    if (updated == true) {
      markAsChanged();
    }
  }
}
