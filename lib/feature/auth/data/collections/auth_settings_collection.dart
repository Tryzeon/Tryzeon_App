import 'package:isar_community/isar.dart';

part 'auth_settings_collection.g.dart';

@collection
class AuthSettingsCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String key = 'default';

  String? lastLoginType;
}
