import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/wardrobe_service.dart';

class UploadWardrobeItemDialog extends StatefulWidget {
  const UploadWardrobeItemDialog({
    super.key,
    required this.image,
    required this.categories,
  });
  final File image;
  final List<String> categories;

  @override
  State<UploadWardrobeItemDialog> createState() => _UploadWardrobeItemDialogState();
}

class _UploadWardrobeItemDialogState extends State<UploadWardrobeItemDialog> {
  String? _selectedCategory;
  final List<String> _selectedTags = [];
  bool _isUploading = false;
  final TextEditingController _customTagController = TextEditingController();

  // 預設的 tag 類別
  static const Map<String, List<String>> _defaultTagCategories = {
    '顏色': ['黑色', '白色', '灰色', '紅色', '藍色', '綠色', '黃色', '粉色', '紫色', '棕色'],
    '風格': ['休閒', '正式', '運動', '街頭', '古著', '韓系', '日系', '歐美'],
    '類型': ['帽T', 'T恤', '襯衫', '牛仔褲', '短褲', '長褲', '洋裝', '外套', '背心'],
    '季節': ['春季', '夏季', '秋季', '冬季', '四季'],
  };

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    setState(() {
      _isUploading = true;
    });

    final result = await WardrobeService.createWardrobeItem(
      widget.image,
      _selectedCategory!,
      tags: _selectedTags,
    );

    if (!mounted) return;

    setState(() {
      _isUploading = false;
    });

    if (result.isSuccess) {
      Navigator.pop(context, true);
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              _buildImagePreview(),
              const SizedBox(height: 24),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildTagSelector(),
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
                      gradient: _selectedCategory != null && !_isUploading
                          ? LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            )
                          : null,
                      color: _selectedCategory == null || _isUploading
                          ? colorScheme.surfaceContainerHighest
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _selectedCategory != null && !_isUploading
                          ? _handleUpload
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
                      child: _isUploading
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

  Widget _buildImagePreview() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(widget.image, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          children: widget.categories.map((final category) {
            final isSelected = _selectedCategory == category;
            return Container(
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [colorScheme.primary, colorScheme.secondary])
                    : null,
                color: isSelected ? null : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected ? null : category;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      category,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
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

  void _toggleTag(final String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isEmpty) return;

    setState(() {
      if (!_selectedTags.contains(tag)) {
        _selectedTags.add(tag);
      }
    });
    _customTagController.clear();
  }

  Widget _buildTagSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((final tag) {
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
                    onTap: () => _toggleTag(tag),
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
                  final isSelected = _selectedTags.contains(tag);
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
                        onTap: () => _toggleTag(tag),
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
                controller: _customTagController,
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
                onSubmitted: (final _) => _addCustomTag(),
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
                  onTap: _addCustomTag,
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
}
