import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_prompt_config.dart';
import 'package:typed_result/typed_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = SettingsRepositoryImpl();

  test('reads back settings saved by v1.13, which used the same keys', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyTryonScenePrompt: '都會街頭',
      AppConstants.keyTryonTransitionPrompt: '一鏡到底',
    });

    final config = (await repository.getTryonPromptConfig()).get()!;
    expect(config.scenePrompt, '都會街頭');
    expect(config.transitionPrompt, '一鏡到底');
  });

  test('reads back what it saved', () async {
    SharedPreferences.setMockInitialValues({});

    await repository.setTryonPromptConfig(
      const TryonPromptConfig(
        scenePrompt: '都會街頭',
        stylingPrompt: '紮進褲頭',
        transitionPrompt: '動態跳剪',
      ),
    );

    final config = (await repository.getTryonPromptConfig()).get()!;
    expect(config.scenePrompt, '都會街頭');
    expect(config.stylingPrompt, '紮進褲頭');
    expect(config.transitionPrompt, '動態跳剪');
  });

  test('clearing a prompt removes its key instead of storing an empty string', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyTryonScenePrompt: '都會街頭',
      AppConstants.keyTryonStylingPrompt: '紮進褲頭',
      AppConstants.keyTryonTransitionPrompt: '動態跳剪',
    });

    await repository.setTryonPromptConfig(const TryonPromptConfig());

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(AppConstants.keyTryonScenePrompt), isFalse);
    expect(prefs.containsKey(AppConstants.keyTryonStylingPrompt), isFalse);
    expect(prefs.containsKey(AppConstants.keyTryonTransitionPrompt), isFalse);

    final config = (await repository.getTryonPromptConfig()).get()!;
    expect(config.hasScene, isFalse);
    expect(config.hasStyling, isFalse);
    expect(config.hasTransition, isFalse);
  });
}
