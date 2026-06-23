import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/widgets/selection_form_field.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_size_voice_input.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_advanced_fields_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_basic_fields_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_image_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_size_list_editor.dart';

class ProductFormLayout extends StatelessWidget {
  const ProductFormLayout({
    required this.formData,
    required this.sizeManager,
    required this.onPickImage,
    required this.productCategoriesAsync,
    required this.onRetryCategories,
    required this.voiceStatus,
    required this.onVoicePressed,
    this.isAnalyzing = false,
    this.advancedController,
    super.key,
  });
  final ProductFormData formData;
  final ProductSizeManager sizeManager;
  final Future<List<File>?> Function(int remainingCount) onPickImage;
  final AsyncValue<List<ProductCategory>> productCategoriesAsync;
  final VoidCallback onRetryCategories;
  final SizeVoiceStatus voiceStatus;
  final VoidCallback onVoicePressed;
  final bool isAnalyzing;
  final ExpansibleController? advancedController;

  @override
  Widget build(final BuildContext context) {
    return Form(
      key: formData.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.smMd,
            ),
            child: _FormSectionLabel(
              number: '01',
              title: '商品圖片',
              helper: '最多 3 張 · 長按拖曳調整順序',
            ),
          ),
          SelectionFormField<List<ImageItem>>(
            controller: formData.images,
            validator: (final value) =>
                AppValidators.validateNonEmpty(value, message: '請選擇至少一張商品圖片'),
            builder: (final state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageEditor(
                  images: formData.images.value,
                  hasError: state.hasError,
                  onImagesChanged: (final updated) => formData.images.value = updated,
                  onPickImage: () async {
                    final currentCount = formData.images.value.length;
                    final remaining = AppConstants.maxProductImages - currentCount;
                    if (remaining <= 0) return;
                    final files = await onPickImage(remaining);
                    if (files != null && files.isNotEmpty) {
                      final newItems = files
                          .map((final f) => ImageItem.newImage(file: f))
                          .toList();
                      formData.images.value = [...formData.images.value, ...newItems];
                    }
                  },
                ),
                if (state.hasError) _ImageErrorText(state.errorText!),
              ],
            ),
          ),
          if (isAnalyzing)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: _AnalyzingIndicator(),
            ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _FormSectionLabel(number: '02', title: '商品資訊'),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductBasicFieldsEditor(
                  nameController: formData.nameController,
                  priceController: formData.priceController,
                  purchaseLinkController: formData.purchaseLinkController,
                  selectedGender: formData.selectedGender,
                  selectedCategoryIds: formData.selectedCategoryIds,
                  productCategoriesAsync: productCategoriesAsync,
                  onRetryCategories: onRetryCategories,
                ),
                const SizedBox(height: AppSpacing.lg),
                ProductAdvancedFieldsEditor(
                  selectedMaterial: formData.selectedMaterial,
                  selectedFit: formData.selectedFit,
                  selectedElasticity: formData.selectedElasticity,
                  selectedThickness: formData.selectedThickness,
                  selectedStyles: formData.selectedStyles,
                  selectedSeasons: formData.selectedSeasons,
                  controller: advancedController,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _FormSectionLabel(number: '03', title: '尺寸資訊'),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ProductSizeListEditor(
              entries: sizeManager.sizeEntries,
              selectedUnit: sizeManager.selectedUnit,
              onUnitChanged: sizeManager.changeUnit,
              onAdd: sizeManager.addSize,
              onRemove: sizeManager.removeSize,
              voiceStatus: voiceStatus,
              onVoicePressed: onVoicePressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.number, required this.title, this.helper});

  final String number;
  final String title;
  final String? helper;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(number, style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: textTheme.titleMedium),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper!,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'AI 分析中…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ImageErrorText extends StatelessWidget {
  const _ImageErrorText(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.lg, 0),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
