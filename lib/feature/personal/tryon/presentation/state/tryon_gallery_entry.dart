import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';

sealed class TryonGalleryEntry {
  const TryonGalleryEntry();

  String get id;

  TryonSubject get subject;

  TryonResult? get result;

  TryonMode get mode => subject.mode;
}

final class PendingTryonEntry extends TryonGalleryEntry {
  const PendingTryonEntry({required this.id, required this.subject});

  @override
  final String id;
  @override
  final TryonSubject subject;
  @override
  TryonResult? get result => null;
}

final class FinishedTryonEntry extends TryonGalleryEntry {
  const FinishedTryonEntry(this.result, this.subject);

  @override
  final TryonResult result;
  @override
  final TryonSubject subject;
  @override
  String get id => result.id;
}
