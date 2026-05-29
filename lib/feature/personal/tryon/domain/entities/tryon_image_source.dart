import 'package:freezed_annotation/freezed_annotation.dart';

part 'tryon_image_source.freezed.dart';

@freezed
sealed class TryOnImageSource with _$TryOnImageSource {
  /// Supabase storage path or R2 'stores/' object key.
  const factory TryOnImageSource.path(final String path) = TryOnImageSourcePath;

  /// Inline base64-encoded image bytes.
  const factory TryOnImageSource.base64(final String data) = TryOnImageSourceBase64;
}
