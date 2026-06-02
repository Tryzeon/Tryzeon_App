import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    final categoriesWithDisplay = CategoryDisplay.allWithDisplayNames;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleUpload() async {
      isUploading.value = true;

      final capabilities = await ref.read(subscriptionCapabilitiesProvider.future);
      final items = await ref.read(wardrobeItemsProvider.future);
      final uploadWardrobeItemUseCase = ref.read(uploadWardrobeItemUseCaseProvider);

      final result = await uploadWardrobeItemUseCase(
        params: CreateWardrobeItemParams(
          image: image,
          category: selectedCategory.value!,
          tags: const [], // tags are now managed entirely on the detail page
        ),
        currentItemCount: items.length,
        wardrobeLimit: capabilities.wardrobeLimit,
      );

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
                  color: percentage >= 0.9 ? colorScheme.error : colorScheme.primary,
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
            child: Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: buildCapacityIndicator()),
        ],
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
                const SizedBox(height: AppSpacing.lg),
                buildCategorySelector(),
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
            onPressed: selectedCategory.value != null && !isUploading.value
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
