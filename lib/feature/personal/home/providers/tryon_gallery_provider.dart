import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';

part 'tryon_gallery_provider.freezed.dart';
part 'tryon_gallery_provider.g.dart';

@freezed
sealed class TryonGalleryState with _$TryonGalleryState {
  const factory TryonGalleryState({
    @Default(<TryonResult>[]) final List<TryonResult> images,
    final String? currentId,
    final String? customAvatarId,
  }) = _TryonGalleryState;

  const TryonGalleryState._();

  TryonResult? get currentResult =>
      images.where((final r) => r.id == currentId).firstOrNull;

  TryonResult? get customAvatarResult =>
      images.where((final r) => r.id == customAvatarId).firstOrNull;

  int get currentIndex =>
      currentId == null ? -1 : images.indexWhere((final r) => r.id == currentId);

  bool get isCurrentTheAvatar => customAvatarId != null && customAvatarId == currentId;
}

@riverpod
class TryonGalleryNotifier extends _$TryonGalleryNotifier {
  @override
  TryonGalleryState build() => const TryonGalleryState();

  void setCurrentId(final String? id) {
    if (state.currentId == id) return;
    state = state.copyWith(currentId: id);
  }

  void addPlaceholder(final TryonResult placeholder) {
    state = state.copyWith(
      images: [...state.images, placeholder],
      currentId: placeholder.id,
    );
  }

  void replaceById(final String requestId, final TryonResult result) {
    final index = state.images.indexWhere((final r) => r.id == requestId);
    if (index == -1) return;
    final next = [...state.images]..[index] = result;
    state = state.copyWith(images: next, currentId: result.id);
  }

  void removeById(final String id) {
    final index = state.images.indexWhere((final r) => r.id == id);
    if (index == -1) return;

    final nextImages = [...state.images]..removeAt(index);

    String? nextCurrent = state.currentId;
    if (nextCurrent == id) {
      if (nextImages.isEmpty) {
        nextCurrent = null;
      } else {
        final fallbackIndex = index.clamp(0, nextImages.length - 1);
        nextCurrent = nextImages[fallbackIndex].id;
      }
    }

    state = state.copyWith(
      images: nextImages,
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
