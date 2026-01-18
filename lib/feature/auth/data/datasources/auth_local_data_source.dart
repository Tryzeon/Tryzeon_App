import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/auth/data/collections/auth_settings_collection.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<String?> getLastLoginType() async {
    final isar = await _isarService.db;
    final settings = await isar.authSettingsCollections.where().findFirst();
    return settings?.lastLoginType;
  }

  Future<void> setLastLoginType(final String type) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final settings =
          await isar.authSettingsCollections.where().findFirst() ??
          AuthSettingsCollection();
      settings.lastLoginType = type;
      await isar.authSettingsCollections.put(settings);
    });
  }

  Future<void> clearLoginType() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final settings = await isar.authSettingsCollections.where().findFirst();
      if (settings != null) {
        settings.lastLoginType = null;
        await isar.authSettingsCollections.put(settings);
      }
    });
  }

  Future<void> clearAll() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
