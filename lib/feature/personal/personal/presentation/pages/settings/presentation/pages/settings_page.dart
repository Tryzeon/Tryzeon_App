import 'package:flutter/material.dart';
import 'package:tryzeon/feature/store/store_entry.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/pages/base_settings_page.dart';
import 'settings_profile_page.dart';

class PersonalSettingsPage extends BaseSettingsPage {
  const PersonalSettingsPage({super.key});

  @override
  BaseSettingsPageState createState() => _PersonalSettingsPageState();
}

class _PersonalSettingsPageState extends BaseSettingsPageState<PersonalSettingsPage> {
  @override
  List<SettingsMenuItem> buildMenuItems() {
    return [
      SettingsMenuItem(
        icon: Icons.person_outline_rounded,
        title: '基本資料',
        subtitle: '編輯您的個人資訊',
        onTap: _navigateToProfile,
      ),
      SettingsMenuItem(
        icon: Icons.store_outlined,
        title: '切換到店家帳號',
        subtitle: '管理您的商店',
        onTap: _switchToStore,
      ),
    ];
  }

  Future<void> _switchToStore() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: '切換帳號',
      content: '你確定要切換到店家版帳號嗎？',
    );

    if (confirmed != true) return;

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const StoreEntry()),
        (final route) => false,
      );
    }
  }

  Future<void> _navigateToProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (final context) => const PersonalProfileSettingsPage()),
    );
    if (updated == true) {
      markAsChanged();
    }
  }
}
