import 'package:isar_community/isar.dart';

part 'auth_settings_cache.g.dart';

@collection
class AuthSettingsCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String key = 'default';

  String? lastLoginType;
}
