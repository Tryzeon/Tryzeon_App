import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';

part 'tryon_coordinator.g.dart';

/// The single public entry point for triggering a try-on from any page (home,
/// shop, wardrobe, chat): switches to the home branch, then delegates to
/// [TryonController]. The home page reacts to the result by listening to the
/// controller's outcome state.
///
/// Navigation stays a bound callback because switching a [StatefulNavigationShell]
/// branch needs the shell's context; execution is a direct provider read, not a
/// bound callback, so a try-on can never silently no-op.
@Riverpod(keepAlive: true)
TryonCoordinator tryonCoordinator(final Ref ref) => TryonCoordinator(ref);

class TryonCoordinator {
  TryonCoordinator(this._ref);

  final Ref _ref;
  VoidCallback? _navigateToHome;

  // ignore: use_setters_to_change_properties
  void bindNavigateToHome(final VoidCallback fn) => _navigateToHome = fn;
  void unbindNavigateToHome(final VoidCallback fn) {
    if (_navigateToHome == fn) _navigateToHome = null;
  }

  /// Starts an image try-on from a locally picked garment photo.
  Future<void> tryonFromLocalImage(final File image) async {
    _navigateToHome?.call();
    await _ref.read(tryonControllerProvider.notifier).tryonFromLocalImage(image);
  }

  /// Starts a try-on from garment images already stored remotely (by path).
  Future<void> tryonFromStoragePaths(
    final List<String> clothesPaths, {
    final TryonMode mode = TryonMode.image,
  }) async {
    _navigateToHome?.call();
    await _ref
        .read(tryonControllerProvider.notifier)
        .tryonFromStoragePaths(clothesPaths, mode: mode);
  }

  /// Starts a try-on for a catalog product by id (backend resolves the garment).
  Future<void> tryonFromProduct(
    final String productId, {
    final TryonMode mode = TryonMode.image,
  }) async {
    _navigateToHome?.call();
    await _ref
        .read(tryonControllerProvider.notifier)
        .tryonFromProduct(productId, mode: mode);
  }
}
