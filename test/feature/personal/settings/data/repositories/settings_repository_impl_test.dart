import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:typed_result/typed_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = SettingsRepositoryImpl();

  test('reads back settings saved by v1.13, which used the same keys', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyTryonScenePrompt: 'urban street',
      AppConstants.keyTryonTransitionPrompt: 'single take',
    });

    final config = (await repository.getTryonPreferences()).get()!;
    expect(config.scenePrompt, 'urban street');
    expect(config.transitionPrompt, 'single take');
    expect(config.engine, TryonEngine.standard);
  });

  test('reads back what it saved', () async {
    SharedPreferences.setMockInitialValues({});

    await repository.setTryonPreferences(
      const TryonPreferences(
        scenePrompt: 'urban street',
        stylingPrompt: 'tucked in',
        transitionPrompt: 'jump cut',
        engine: TryonEngine.advanced,
      ),
    );

    final config = (await repository.getTryonPreferences()).get()!;
    expect(config.scenePrompt, 'urban street');
    expect(config.stylingPrompt, 'tucked in');
    expect(config.transitionPrompt, 'jump cut');
    expect(config.engine, TryonEngine.advanced);
  });

  test('falls back to the standard engine when the stored name is unknown', () async {
    SharedPreferences.setMockInitialValues({AppConstants.keyTryonEngine: 'turbo'});

    final config = (await repository.getTryonPreferences()).get()!;
    expect(config.engine, TryonEngine.standard);
  });

  test('clearing a prompt removes its key instead of storing an empty string', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyTryonScenePrompt: 'urban street',
      AppConstants.keyTryonStylingPrompt: 'tucked in',
      AppConstants.keyTryonTransitionPrompt: 'jump cut',
    });

    await repository.setTryonPreferences(const TryonPreferences());

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(AppConstants.keyTryonScenePrompt), isFalse);
    expect(prefs.containsKey(AppConstants.keyTryonStylingPrompt), isFalse);
    expect(prefs.containsKey(AppConstants.keyTryonTransitionPrompt), isFalse);

    final config = (await repository.getTryonPreferences()).get()!;
    expect(config.hasScene, isFalse);
    expect(config.hasStyling, isFalse);
    expect(config.hasTransition, isFalse);
    expect(config.hasCustomEngine, isFalse);
  });
}
