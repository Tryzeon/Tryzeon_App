import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_subject.freezed.dart';

/// What a gallery entry is a try-on of, and enough to run it again.
///
/// Holds only what the app cannot rebuild: the avatar and the preferences are
/// read fresh on every run, so regenerating picks up a changed setting.
@freezed
sealed class TryonSubject with _$TryonSubject {
  const factory TryonSubject.generate({
    required final List<TryonGarment> garments,
    required final TryonMode mode,
  }) = TryonSubjectGenerate;

  /// An animate request carries no garments, so [origin] is the only thing that
  /// can say what the video shows.
  const factory TryonSubject.animated({
    required final String baseImageUrl,
    required final TryonSubject origin,
  }) = TryonSubjectAnimated;

  const TryonSubject._();

  TryonMode get mode => switch (this) {
    TryonSubjectGenerate(:final mode) => mode,
    TryonSubjectAnimated() => TryonMode.video,
  };

  String? get productId => switch (this) {
    TryonSubjectGenerate(:final garments) =>
      garments.whereType<TryonGarmentProduct>().firstOrNull?.productId,
    TryonSubjectAnimated(:final origin) => origin.productId,
  };
}
