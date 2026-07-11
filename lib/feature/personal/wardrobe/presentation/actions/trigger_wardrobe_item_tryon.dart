import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/main/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/shop/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

/// Shows the try-on mode picker for [item], then starts try-on with the
/// selected mode via [tryOnCoordinatorProvider].
void triggerWardrobeItemTryOn(
  final BuildContext context,
  final WidgetRef ref,
  final WardrobeItem item, {
  required final bool hasVideoAccess,
}) {
  HapticFeedback.mediumImpact();
  TryOnModeSheet.show(
    context: context,
    hasVideoAccess: hasVideoAccess,
    onModeSelected: (final mode) =>
        ref.read(tryOnCoordinatorProvider).tryOnFromStorage([item.imagePath], mode: mode),
  );
}
