import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((final ref) {
  return SettingsRepositoryImpl();
});

final recommendNearbyShopsProvider =
    AsyncNotifierProvider<RecommendNearbyShopsNotifier, bool>(
      RecommendNearbyShopsNotifier.new,
    );

class RecommendNearbyShopsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    return repository.getRecommendNearbyShops();
  }

  Future<void> toggle(final bool value) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setRecommendNearbyShops(value);
    state = AsyncData(value);
  }
}
