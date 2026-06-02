import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_category_selector.dart';

class ProductBasicFieldsEditor extends HookWidget {
  const ProductBasicFieldsEditor({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.selectedGender,
    required this.selectedWardrobeCategory,
    required this.selectedCategoryIds,
    required this.productCategoryTreeAsync,
    required this.onRetryCategories,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<ProductGender> selectedGender;
  final ValueNotifier<WardrobeCategory?> selectedWardrobeCategory;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final AsyncValue<List<CategoryTreeNode>> productCategoryTreeAsync;
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('分類', required: true),
        productCategoryTreeAsync.when(
          data: (final categoryTree) => FormField<Set<String>>(
            initialValue: selectedCategoryIds.value,
            validator: (final value) =>
                AppValidators.validateNonEmpty(value, message: '請選擇至少一種商品類型'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (final state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductCategorySelector(
                  categoryTree: categoryTree,
                  selectedCategoryIds: selectedCategoryIds,
                  hasError: state.hasError,
                  onChanged: (final newIds) {
                    selectedCategoryIds.value = newIds;
                    state.didChange(newIds);
                  },
                ),
                if (state.hasError) _ErrorText(state.errorText!),
              ],
            ),
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
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('性別', required: true),
        ProductGenderSelector(selectedGender: selectedGender),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('衣櫥分類', required: true),
        FormField<WardrobeCategory?>(
          initialValue: selectedWardrobeCategory.value,
          validator: (final value) => value == null ? '請選擇衣櫥分類' : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (final state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductWardrobeCategorySelector(
                selectedWardrobeCategory: selectedWardrobeCategory,
                onChanged: state.didChange,
              ),
              if (state.hasError) _ErrorText(state.errorText!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('購買連結'),
        TextFormField(
          controller: purchaseLinkController,
          focusNode: purchaseLinkFocusNode,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (final _) => FocusScope.of(context).unfocus(),
          validator: AppValidators.validateUrl,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
