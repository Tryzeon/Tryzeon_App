import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';

part 'tryon_coordinator.g.dart';

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

  Future<void> tryonFromLocalImage(
    final File image, {
    final TryonMode mode = TryonMode.image,
  }) async {
    _navigateToHome?.call();
    await _ref
        .read(tryonControllerProvider.notifier)
        .tryonFromLocalImage(image, mode: mode);
  }

  Future<void> tryonFromWardrobeItem(
    final String wardrobeItemId, {
    final TryonMode mode = TryonMode.image,
  }) async {
    _navigateToHome?.call();
    await _ref
        .read(tryonControllerProvider.notifier)
        .tryonFromWardrobeItem(wardrobeItemId, mode: mode);
  }

  Future<void> tryonFromProduct(
    final String productId, {
    final String? sizeId,
    final TryonMode mode = TryonMode.image,
  }) async {
    _navigateToHome?.call();
    await _ref
        .read(tryonControllerProvider.notifier)
        .tryonFromProduct(productId, sizeId: sizeId, mode: mode);
  }
}
