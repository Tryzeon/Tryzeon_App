import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';

part 'tryon_gallery_provider.freezed.dart';
part 'tryon_gallery_provider.g.dart';

@freezed
sealed class TryonGalleryState with _$TryonGalleryState {
  const factory TryonGalleryState({
    @Default(<TryonGalleryEntry>[]) final List<TryonGalleryEntry> entries,
    final String? currentId,
    final String? customAvatarId,
  }) = _TryonGalleryState;

  const TryonGalleryState._();

  TryonGalleryEntry? get currentEntry =>
      entries.where((final e) => e.id == currentId).firstOrNull;

  /// The finished result in view — null on the avatar page or while the current
  /// entry is still pending.
  TryonResult? get currentResult => switch (currentEntry) {
    FinishedTryonEntry(:final result) => result,
    _ => null,
  };

  bool get isCurrentPending => currentEntry is PendingTryonEntry;

  TryonResult? get customAvatarResult {
    final entry = entries.where((final e) => e.id == customAvatarId).firstOrNull;
    return switch (entry) {
      FinishedTryonEntry(:final result) => result,
      _ => null,
    };
  }

  int get currentIndex =>
      currentId == null ? -1 : entries.indexWhere((final e) => e.id == currentId);

  bool get isCurrentTheAvatar => customAvatarId != null && customAvatarId == currentId;
}

@Riverpod(keepAlive: true)
class TryonGalleryNotifier extends _$TryonGalleryNotifier {
  @override
  TryonGalleryState build() => const TryonGalleryState();

  void setCurrentId(final String? id) {
    if (state.currentId == id) return;
    state = state.copyWith(currentId: id);
  }

  /// Inserts the pending placeholder for a try-on that just started.
  void addPending({required final String id, required final TryonMode mode}) {
    state = state.copyWith(
      entries: [
        ...state.entries,
        PendingTryonEntry(id: id, mode: mode),
      ],
      currentId: id,
    );
  }

  /// Swaps the pending entry for its finished [result].
  void completeById(final String id, final TryonResult result) {
    final index = state.entries.indexWhere((final e) => e.id == id);
    if (index == -1) return;
    final next = [...state.entries]..[index] = FinishedTryonEntry(result);
    state = state.copyWith(entries: next, currentId: result.id);
  }

  void removeById(final String id) {
    final index = state.entries.indexWhere((final e) => e.id == id);
    if (index == -1) return;

    final nextEntries = [...state.entries]..removeAt(index);

    String? nextCurrent = state.currentId;
    if (nextCurrent == id) {
      if (nextEntries.isEmpty) {
        nextCurrent = null;
      } else {
        final fallbackIndex = index.clamp(0, nextEntries.length - 1);
        nextCurrent = nextEntries[fallbackIndex].id;
      }
    }

    state = state.copyWith(
      entries: nextEntries,
      currentId: nextCurrent,
      customAvatarId: state.customAvatarId == id ? null : state.customAvatarId,
    );
  }

  void toggleAvatarForCurrent() {
    final id = state.currentId;
    if (id == null) return;
    state = state.copyWith(customAvatarId: state.customAvatarId == id ? null : id);
  }

  void deleteCurrent() {
    final id = state.currentId;
    if (id == null) return;
    removeById(id);
  }
}
