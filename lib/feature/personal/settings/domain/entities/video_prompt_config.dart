import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_prompt_config.freezed.dart';

@freezed
sealed class VideoPromptConfig with _$VideoPromptConfig {
  const factory VideoPromptConfig({
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _VideoPromptConfig;
  const VideoPromptConfig._();
}
