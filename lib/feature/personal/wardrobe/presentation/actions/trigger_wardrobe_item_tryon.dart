import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

void triggerWardrobeItemTryon(
  final BuildContext context,
  final WidgetRef ref,
  final WardrobeItem item,
) {
  HapticFeedback.mediumImpact();
  TryonModeSheet.show(
    context: context,
    onModeSelected: (final mode) =>
        ref.read(tryonCoordinatorProvider).tryonFromWardrobeItem(item.id, mode: mode),
  );
}
