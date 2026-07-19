import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';


sealed class TryonGalleryEntry {
  const TryonGalleryEntry();

  String get id;
  TryonMode get mode;
}

final class PendingTryonEntry extends TryonGalleryEntry {
  const PendingTryonEntry({required this.id, required this.mode});

  @override
  final String id;
  @override
  final TryonMode mode;
}

final class FinishedTryonEntry extends TryonGalleryEntry {
  const FinishedTryonEntry(this.result);

  final TryonResult result;

  @override
  String get id => result.id;
  @override
  TryonMode get mode => result.mode;
}
