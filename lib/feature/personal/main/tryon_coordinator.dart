import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_coordinator.g.dart';

typedef TryOnFromStorageFn =
    Future<void> Function(List<String> clothesPaths, {TryOnMode mode});

class TryOnCoordinator {
  VoidCallback? _navigateToHome;
  TryOnFromStorageFn? _tryOnFromStorage;

  // ignore: use_setters_to_change_properties
  void bindNavigateToHome(final VoidCallback fn) => _navigateToHome = fn;
  void unbindNavigateToHome(final VoidCallback fn) {
    if (_navigateToHome == fn) _navigateToHome = null;
  }

  // ignore: use_setters_to_change_properties
  void bindTryOnFromStorage(final TryOnFromStorageFn fn) => _tryOnFromStorage = fn;
  void unbindTryOnFromStorage(final TryOnFromStorageFn fn) {
    if (_tryOnFromStorage == fn) _tryOnFromStorage = null;
  }

  Future<void> tryOnFromStorage(
    final List<String> clothesPaths, {
    final TryOnMode mode = TryOnMode.image,
  }) async {
    _navigateToHome?.call();
    await _tryOnFromStorage?.call(clothesPaths, mode: mode);
  }
}

@Riverpod(keepAlive: true)
TryOnCoordinator tryOnCoordinator(final Ref ref) => TryOnCoordinator();
