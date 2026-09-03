import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';

part 'tryon_preferences.freezed.dart';

/// Scene and styling apply to both image and video try-on; transition is
/// video-only.
@freezed
sealed class TryonPreferences with _$TryonPreferences {
  const factory TryonPreferences({
    final String? scenePrompt,
    final String? stylingPrompt,
    final String? transitionPrompt,
    @Default(TryonEngine.standard) final TryonEngine engine,
  }) = _TryonPreferences;
  const TryonPreferences._();

  bool get hasScene => scenePrompt?.isNotEmpty ?? false;
  bool get hasStyling => stylingPrompt?.isNotEmpty ?? false;
  bool get hasTransition => transitionPrompt?.isNotEmpty ?? false;
  bool get hasCustomEngine => engine != TryonEngine.standard;
}
