import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/selection_form_field.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_category_selector.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_gender_selector.dart';

class ProductBasicFieldsEditor extends HookWidget {
  const ProductBasicFieldsEditor({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.selectedGender,
    required this.selectedCategoryId,
    required this.productCategoriesAsync,
    required this.onRetryCategories,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<ProductGender?> selectedGender;
  final ValueNotifier<String?> selectedCategoryId;
  final AsyncValue<List<ProductCategory>> productCategoriesAsync;
  final VoidCallback onRetryCategories;

  @override
  Widget build(final BuildContext context) {
    final priceFocusNode = useFocusNode();
    final purchaseLinkFocusNode = useFocusNode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('商品名稱', required: true),
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(hintText: '輸入商品名稱'),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (final _) => priceFocusNode.requestFocus(),
          validator: AppValidators.validateProductName,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('價格 · TWD', required: true),
        TextFormField(
          controller: priceController,
          focusNode: priceFocusNode,
          decoration: const InputDecoration(hintText: '請輸入價格'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (final _) => purchaseLinkFocusNode.requestFocus(),
          validator: AppValidators.validatePrice,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('性別', required: true),
        SelectionFormField<ProductGender?>(
          controller: selectedGender,
          validator: (final value) =>
              AppValidators.validateNonEmpty(value, message: '請選擇性別'),
          builder: (final state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductGenderSelector(selectedGender: selectedGender),
              if (state.hasError) _ErrorText(state.errorText!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('分類', required: true),
        SelectionFormField<String?>(
          controller: selectedCategoryId,
          validator: (final value) =>
              AppValidators.validateNonEmpty(value, message: '請選擇商品分類'),
          builder: (final state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              productCategoriesAsync.when(
                data: (final categories) => ProductCategorySelector(
                  categories: categories,
                  selectedCategoryId: selectedCategoryId,
                  hasError: state.hasError,
                  onChanged: (final newId) => selectedCategoryId.value = newId,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (final error, final stack) => ErrorView(
                  message: error.displayMessage(context),
                  onRetry: onRetryCategories,
                  isCompact: true,
                ),
              ),
              if (state.hasError) _ErrorText(state.errorText!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('購買連結（選填）'),
        TextFormField(
          controller: purchaseLinkController,
          focusNode: purchaseLinkFocusNode,
          decoration: const InputDecoration(
            hintText: 'https://...',
            helperText: '留空則顧客會透過你在「設定 → 店家資料」中的訂購聯絡方式私訊下單',
            helperMaxLines: 2,
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (final _) => FocusScope.of(context).unfocus(),
          validator: AppValidators.validateUrl,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
        style: labelStyle,
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.mdLg),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
