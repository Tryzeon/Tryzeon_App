import 'package:freezed_annotation/freezed_annotation.dart';

part 'tryon_image_source.freezed.dart';

@freezed
sealed class TryonImageSource with _$TryonImageSource {
  /// Supabase storage path or R2 'stores/' object key.
  const factory TryonImageSource.path(final String path) = TryonImageSourcePath;

  /// Inline base64-encoded image bytes.
  const factory TryonImageSource.base64(final String data) = TryonImageSourceBase64;
}
