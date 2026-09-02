import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
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

  /// Index of the entry in view, or -1 for the avatar page. Entry ids are
  /// non-null, so a null [currentId] never matches and yields -1.
  int get currentIndex => entries.indexWhere((final e) => e.id == currentId);

  /// The gallery page in view. Page 0 is the avatar; entry `i` is page `i + 1`.
  int get currentPage => currentIndex + 1;

  bool get isAvatarPage => currentIndex == -1;

  TryonGalleryEntry? get currentEntry => isAvatarPage ? null : entries[currentIndex];

  /// The finished result in view — null on the avatar page or while the current
  /// entry is still pending.
  TryonResult? get currentResult => currentEntry?.result;

  bool get isCurrentPending => currentEntry is PendingTryonEntry;

  TryonResult? get customAvatarResult =>
      entries.where((final e) => e.id == customAvatarId).firstOrNull?.result;

  bool get isCurrentTheAvatar => currentId != null && currentId == customAvatarId;
}

@Riverpod(keepAlive: true)
class TryonGalleryNotifier extends _$TryonGalleryNotifier {
  @override
  TryonGalleryState build() {
    ref.watch(isAuthenticatedProvider);
    return const TryonGalleryState();
  }

  void setCurrentPage(final int page) {
    final index = page - 1;
    final id = index >= 0 && index < state.entries.length
        ? state.entries[index].id
        : null;
    if (state.currentId == id) return;
    state = state.copyWith(currentId: id);
  }

  void showAvatarPage() => setCurrentPage(0);

  /// Inserts the pending placeholder for a try-on that just started.
  void addPending({
    required final String id,
    required final TryonSubject subject,
  }) {
    state = state.copyWith(
      entries: [
        ...state.entries,
        PendingTryonEntry(id: id, subject: subject),
      ],
      currentId: id,
    );
  }

  /// Swaps the placeholder for its finished result. False when the entry is
  /// gone — the user dropped it while the try-on was still running.
  bool complete(final TryonResult result) {
    final index = state.entries.indexWhere((final e) => e.id == result.id);
    if (index == -1) return false;
    state = state.copyWith(
      entries: [...state.entries]
        ..[index] = FinishedTryonEntry(result, state.entries[index].subject),
    );
    return true;
  }

  /// Drops [id] from the gallery. False when it was already gone.
  bool removeById(final String id) {
    final index = state.entries.indexWhere((final e) => e.id == id);
    if (index == -1) return false;

    final nextEntries = [...state.entries]..removeAt(index);

    // Removing the entry in view falls back to its neighbour, or to the avatar
    // page when nothing is left.
    final nextCurrent = state.currentId != id
        ? state.currentId
        : (nextEntries.isEmpty
              ? null
              : nextEntries[index.clamp(0, nextEntries.length - 1)].id);

    state = state.copyWith(
      entries: nextEntries,
      currentId: nextCurrent,
      customAvatarId: state.customAvatarId == id ? null : state.customAvatarId,
    );
    return true;
  }

  void toggleAvatarForCurrent() {
    final id = state.currentId;
    if (id == null) return;
    state = state.copyWith(customAvatarId: state.customAvatarId == id ? null : id);
  }
}
