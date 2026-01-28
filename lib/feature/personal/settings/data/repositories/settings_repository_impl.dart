import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<bool> getRecommendNearbyShops() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyRecommendNearbyShops) ?? false;
  }

  @override
  Future<void> setRecommendNearbyShops(final bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyRecommendNearbyShops, value);
  }
}
