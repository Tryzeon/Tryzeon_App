import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/shared/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setLastLoginType saves the correct type', () async {
      await AuthService.setLastLoginType(UserType.store);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_login_type'), 'store');
    });

    test('getLastLoginType returns correct type when set', () async {
      SharedPreferences.setMockInitialValues({'last_login_type': 'store'});

      final type = await AuthService.getLastLoginType();
      expect(type, UserType.store);
    });

    test('getLastLoginType returns null when not set', () async {
      SharedPreferences.setMockInitialValues({});

      final type = await AuthService.getLastLoginType();
      expect(type, null);
    });

    test('getLastLoginType returns default when invalid', () async {
      SharedPreferences.setMockInitialValues({'last_login_type': 'invalid_type'});

      // The implementation defaults to UserType.personal in orElse
      final type = await AuthService.getLastLoginType();
      expect(type, UserType.personal);
    });
  });
}
