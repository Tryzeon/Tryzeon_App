import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._prefs);
  final SharedPreferences _prefs;
  static const _lastLoginTypeKey = 'last_login_type';

  String? getLastLoginType() {
    return _prefs.getString(_lastLoginTypeKey);
  }

  Future<void> setLastLoginType(final String type) async {
    await _prefs.setString(_lastLoginTypeKey, type);
  }

  Future<void> clearLoginType() async {
    await _prefs.remove(_lastLoginTypeKey);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
