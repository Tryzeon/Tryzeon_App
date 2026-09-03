import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';

class ProductImageEditor extends StatelessWidget {
  const ProductImageEditor({
    super.key,
    required this.images,
    required this.onImagesChanged,
    required this.onPickImage,
    this.maxImages = AppConstants.maxProductImages,
    this.hasError = false,
  });

  final List<ImageItem> images;
  final ValueChanged<List<ImageItem>> onImagesChanged;
  final VoidCallback onPickImage;
  final int maxImages;
  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final canAddMore = images.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text(
                '${images.length}/$maxImages',
                style: textTheme.labelMedium?.copyWith(
                  color: images.length >= maxImages
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),
        if (images.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: onPickImage,
              child: _AddPlaceholder(hasError: hasError),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              buildDefaultDragHandles: false,
              proxyDecorator: (final child, final _, final _) => Material(
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                child: child,
              ),
              itemCount: images.length + (canAddMore ? 1 : 0),
              onReorderItem: (final oldIndex, final newIndex) {
                if (oldIndex >= images.length) return;
                final updated = List<ImageItem>.from(images);
                final item = updated.removeAt(oldIndex);
                updated.insert(newIndex.clamp(0, updated.length), item);
                onImagesChanged(updated);
              },
              itemBuilder: (final context, final index) {
                if (index == images.length) {
                  return Padding(
                    key: const ValueKey('add-tile'),
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(onTap: onPickImage, child: const _AddTile()),
                  );
                }
                final item = images[index];
                return Padding(
                  key: ValueKey(item),
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: _ImageCard(
                      item: item,
                      onRemove: () {
                        final updated = List<ImageItem>.from(images)..removeAt(index);
                        onImagesChanged(updated);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.item, required this.onRemove});

  final ImageItem item;
  final VoidCallback onRemove;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.buttonAll,
            child: switch (item) {
              ExistingImageItem(:final url, :final path) => CachedNetworkImage(
                imageUrl: url,
                cacheKey: path,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (final context, final url) =>
                    Container(color: colorScheme.surfaceContainerLow),
                errorWidget: (final context, final url, final error) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
              NewImageItem(:final file) => Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colorScheme.scrim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: AppRadius.buttonAll,
        border: Border.all(
          color: colorScheme.outline,
          width: AppStroke.regular,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Icon(Icons.add_rounded, color: colorScheme.onSurfaceVariant, size: 24),
      ),
    );
  }
}

class _AddPlaceholder extends StatelessWidget {
  const _AddPlaceholder({this.hasError = false});

  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.buttonAll,
        border: Border.all(
          color: hasError ? colorScheme.error : colorScheme.outline,
          width: AppStroke.regular,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '點擊新增',
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
