import 'package:freezed_annotation/freezed_annotation.dart';

part 'tryon_prompt_config.freezed.dart';

/// Scene applies to both image and video try-on; transition is video-only.
@freezed
sealed class TryonPromptConfig with _$TryonPromptConfig {
  const factory TryonPromptConfig({
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _TryonPromptConfig;
  const TryonPromptConfig._();

  bool get hasScene => scenePrompt?.isNotEmpty ?? false;
  bool get hasTransition => transitionPrompt?.isNotEmpty ?? false;
}
