import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class WardrobeItemBubble extends StatelessWidget {
  const WardrobeItemBubble({super.key, required this.item});

  final WardrobeItem item;

  @override
  Widget build(final BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(AppRoutes.personalWardrobeItemPath(item.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _WardrobeImage(imagePath: item.imagePath),
                ),
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Chip(label: Text('你的衣櫃')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WardrobeImage extends ConsumerWidget {
  const _WardrobeImage({required this.imagePath});
  final String imagePath;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final fileAsync = ref.watch(wardrobeItemImageProvider(imagePath));
    return fileAsync.when(
      data: (final file) => Image.file(file, fit: BoxFit.cover),
      loading: () => Container(color: colorScheme.surfaceContainerLow),
      error: (final _, final _) =>
          Icon(Icons.image_not_supported_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}
