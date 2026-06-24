import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

class UploadWardrobeItemSheet extends HookConsumerWidget {
  const UploadWardrobeItemSheet({super.key, required this.image});
  final File image;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedCategory = useState<WardrobeCategory?>(null);
    final isUploading = useState(false);
    final tags = useState<List<String>>(const []);
    final tagController = useTextEditingController();
    final removedBgImage = useState<Uint8List?>(null);
    final useRemovedBg = useState(true);
    final isAnalyzingTags = useState(true);

    useEffect(() {
      var cancelled = false;
      final usecase = ref.read(analyzeWardrobeImageUseCaseProvider);

      Future<void> runBackground() async {
        final bg = await usecase.removeBackground(image);
        if (!cancelled) removedBgImage.value = bg;
      }

      Future<void> runLabels() async {
        final result = await usecase.labels(image);
        if (cancelled) return;
        tags.value = result.tags;
        if (result.category != null && selectedCategory.value == null) {
          selectedCategory.value = result.category;
        }
        isAnalyzingTags.value = false;
      }

      runBackground();
      runLabels();
      return () => cancelled = true;
    }, const []);

    final categoriesWithDisplay = CategoryDisplay.allWithDisplayNames;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void addTag() {
      final text = tagController.text.trim();
      if (text.isEmpty) return;
      if (!tags.value.contains(text)) {
        tags.value = [...tags.value, text];
      }
      tagController.clear();
    }

    void removeTag(final int index) {
      tags.value = List<String>.of(tags.value)..removeAt(index);
    }

    Future<File> resolveUploadFile() async {
      final bytes = removedBgImage.value;
      if (!useRemovedBg.value || bytes == null) return image;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/wardrobe_nobg_${image.uri.pathSegments.last}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return file;
    }

    Future<void> handleUpload() async {
      final pendingTag = tagController.text.trim();
      if (pendingTag.isNotEmpty) addTag();

      isUploading.value = true;

      final capabilities = await ref.read(subscriptionCapabilitiesProvider.future);
      final items = await ref.read(wardrobeItemsProvider.future);
      final uploadWardrobeItemUseCase = ref.read(uploadWardrobeItemUseCaseProvider);

      final uploadFile = await resolveUploadFile();

      final result = await uploadWardrobeItemUseCase(
        params: CreateWardrobeItemParams(
          image: uploadFile,
          category: selectedCategory.value!,
          tags: tags.value,
        ),
        currentItemCount: items.length,
        wardrobeLimit: capabilities.wardrobeLimit,
      );

      if (uploadFile.path != image.path) {
        try {
          await uploadFile.delete();
        } catch (_) {
          // Best-effort cleanup; a leftover temp file is non-fatal.
        }
      }

      if (!context.mounted) return;

      isUploading.value = false;

      if (result.isSuccess) {
        ref.invalidate(wardrobeItemsProvider);
        Navigator.pop(context, selectedCategory.value);
      } else {
        final failure = result.getError()!;

        if (failure is ValidationFailure) {
          UpgradeDialog.show(
            context,
            title: '衣櫃已達上限',
            content: '您的衣櫃容量已達上限\n升級至更高方案以獲得更多儲存空間！',
          );
        } else {
          TopNotification.show(context, message: failure.displayMessage(context));
        }
      }
    }

    Widget buildCapacityIndicator() {
      final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
      final itemsAsync = ref.watch(wardrobeItemsProvider);

      return switch ((capabilitiesAsync, itemsAsync)) {
        (AsyncData(value: final capabilities), AsyncData(value: final items)) => () {
          final limit = capabilities.wardrobeLimit;
          final current = items.length;
          final percentage = current / limit;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '衣櫃容量',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$current / $limit 件',
                    style: textTheme.labelMedium?.copyWith(
                      color: percentage >= 0.9 ? colorScheme.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.buttonAll,
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: colorScheme
                      .surfaceContainerHighest, // usually mapped from colorScheme, mapped as outlineVariant
                  color: percentage >= 0.9 ? colorScheme.error : colorScheme.onSurface,
                ),
              ),
            ],
          );
        }(),
        _ => const SizedBox.shrink(),
      };
    }

    Widget buildImagePreviewRow() {
      return Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: useRemovedBg.value && removedBgImage.value != null
                ? Image.memory(
                    removedBgImage.value!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: buildCapacityIndicator()),
        ],
      );
    }

    Widget buildBackgroundToggle() {
      if (removedBgImage.value == null) return const SizedBox.shrink();
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('自動去背', style: textTheme.labelLarge),
        value: useRemovedBg.value,
        onChanged: (final v) => useRemovedBg.value = v,
      );
    }

    Widget buildCategorySelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選擇類別 *',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: categoriesWithDisplay.map((final entry) {
              final category = entry.key;
              final displayName = entry.value;
              final isSelected = selectedCategory.value == category;

              return ChoiceChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (final selected) => selectedCategory.value = category,
              );
            }).toList(),
          ),
        ],
      );
    }

    Widget buildTagEditor() {
      if (isAnalyzingTags.value) {
        return Row(
          children: [
            const SizedBox(
              width: AppSpacing.md,
              height: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '分析中…',
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '標籤',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: tagController,
            textInputAction: TextInputAction.done,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '新增標籤...',
              suffixIcon: GestureDetector(
                onTap: addTag,
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.add_rounded, color: colorScheme.onSurfaceVariant),
              ),
            ),
            onSubmitted: (final _) => addTag(),
          ),
          if (tags.value.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in tags.value.asMap().entries)
                  Chip(
                    label: Text('#${entry.value}'.toUpperCase()),
                    onDeleted: () => removeTag(entry.key),
                  ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text('上傳衣服', style: textTheme.titleMedium),
        ),
        // Scrollable content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildImagePreviewRow(),
                if (removedBgImage.value != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  buildBackgroundToggle(),
                ],
                const SizedBox(height: AppSpacing.lg),
                buildCategorySelector(),
                const SizedBox(height: AppSpacing.lg),
                buildTagEditor(),
              ],
            ),
          ),
        ),
        // Footer
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.of(context).padding.bottom + AppSpacing.md, // bottom safe area
          ),
          child: FilledButton(
            onPressed:
                selectedCategory.value != null &&
                    !isUploading.value &&
                    !isAnalyzingTags.value
                ? handleUpload
                : null,
            child: isUploading.value
                ? SizedBox(
                    width: AppSpacing.mdLg,
                    height: AppSpacing.mdLg,
                    child: CircularProgressIndicator(
                      strokeWidth: AppStroke.regular,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Text('上傳'),
          ),
        ),
      ],
    );
  }
}
