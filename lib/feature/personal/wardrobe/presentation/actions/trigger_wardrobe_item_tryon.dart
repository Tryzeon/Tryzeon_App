import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

/// Shows the try-on mode picker for [item], then starts try-on with the
/// selected mode via [tryonCoordinatorProvider].
void triggerWardrobeItemTryon(
  final BuildContext context,
  final WidgetRef ref,
  final WardrobeItem item,
) {
  HapticFeedback.mediumImpact();
  TryonModeSheet.show(
    context: context,
    onModeSelected: (final mode) => ref
        .read(tryonCoordinatorProvider)
        .tryonFromStoragePaths([item.imagePath], mode: mode),
  );
}
