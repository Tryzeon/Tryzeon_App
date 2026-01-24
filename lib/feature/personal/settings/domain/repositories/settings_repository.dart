abstract class SettingsRepository {
  Future<bool> getRecommendNearbyShops();
  Future<void> setRecommendNearbyShops(final bool value);
}
