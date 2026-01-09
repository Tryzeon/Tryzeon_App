import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/providers.dart';
import 'package:typed_result/typed_result.dart';
import '../mappers/category_display_mapper.dart';

class UploadWardrobeItemDialog extends HookConsumerWidget {
  const UploadWardrobeItemDialog({super.key, required this.image});
  final File image;

  static const Map<String, List<String>> _defaultTagCategories = {
    '顏色': ['黑色', '白色', '灰色', '紅色', '藍色', '綠色', '黃色', '粉色', '紫色', '棕色'],
    '風格': ['休閒', '正式', '運動', '街頭', '古著', '韓系', '日系', '歐美'],
    '類型': ['帽T', 'T恤', '襯衫', '牛仔褲', '短褲', '長褲', '洋裝', '外套', '背心'],
    '季節': ['春季', '夏季', '秋季', '冬季', '四季'],
  };

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedCategory = useState<WardrobeCategory?>(null);
    final selectedTags = useState<List<String>>([]);
    final isUploading = useState(false);
    final customTagController = useTextEditingController();

    // Get all categories with display names for UI
    final categoriesWithDisplay = CategoryDisplay.allWithDisplayNames;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleUpload() async {
      isUploading.value = true;

      final useCase = ref.read(uploadWardrobeItemUseCaseProvider);
      final result = await useCase(
        image: image,
        category: selectedCategory.value!,
        tags: selectedTags.value,
      );

      if (!context.mounted) return;

      isUploading.value = false;

      if (result.isSuccess) {
        ref.invalidate(wardrobeItemsProvider);
        Navigator.pop(context, true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    void toggleTag(final String tag) {
      if (selectedTags.value.contains(tag)) {
        selectedTags.value = selectedTags.value.where((final t) => t != tag).toList();
      } else {
        selectedTags.value = [...selectedTags.value, tag];
      }
    }

    void addCustomTag() {
      final tag = customTagController.text.trim();
      if (tag.isEmpty) return;

      if (!selectedTags.value.contains(tag)) {
        selectedTags.value = [...selectedTags.value, tag];
      }
      customTagController.clear();
    }

    Widget buildImagePreview() {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(image, fit: BoxFit.cover),
        ),
      );
    }

    Widget buildCategorySelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選擇類別',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoriesWithDisplay.map((final entry) {
              final category = entry.key;
              final displayName = entry.value;
              final isSelected = selectedCategory.value == category;
              return Container(
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        )
                      : null,
                  color: isSelected ? null : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      selectedCategory.value = isSelected ? null : category;
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        displayName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    Widget buildTagSelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '選擇標籤',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(可選)',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 顯示已選擇的 tags
          if (selectedTags.value.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedTags.value.map((final tag) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => toggleTag(tag),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close, color: colorScheme.onPrimary, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // 預設 tags 分類顯示
          ..._defaultTagCategories.entries.map((final entry) {
            final category = entry.key;
            final tags = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((final tag) {
                    final isSelected = selectedTags.value.contains(tag);
                    return Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.2),
                                  colorScheme.secondary.withValues(alpha: 0.2),
                                ],
                              )
                            : null,
                        color: isSelected ? null : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: colorScheme.primary, width: 1.5)
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => toggleTag(tag),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              tag,
                              style: textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          // 自訂 tag 輸入框 (移到最下面)
          Text(
            '自訂標籤',
            style: textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customTagController,
                  decoration: InputDecoration(
                    hintText: '輸入自訂標籤',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (final _) => addCustomTag(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: addCustomTag,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.add, color: colorScheme.onPrimary, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '上傳衣物',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              buildImagePreview(),
              const SizedBox(height: 24),
              buildCategorySelector(),
              const SizedBox(height: 24),
              buildTagSelector(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '取消',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: selectedCategory.value != null && !isUploading.value
                          ? LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            )
                          : null,
                      color: selectedCategory.value == null || isUploading.value
                          ? colorScheme.surfaceContainerHighest
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: selectedCategory.value != null && !isUploading.value
                          ? handleUpload
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isUploading.value
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('上傳'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
