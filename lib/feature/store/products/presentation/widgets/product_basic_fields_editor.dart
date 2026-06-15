import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
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
    required this.selectedCategoryIds,
    required this.productCategoriesAsync,
    required this.onRetryCategories,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<ProductGender> selectedGender;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final AsyncValue<List<ProductCategory>> productCategoriesAsync;
  final VoidCallback onRetryCategories;

  @override
  Widget build(final BuildContext context) {
    final priceFocusNode = useFocusNode();
    final purchaseLinkFocusNode = useFocusNode();

    // Only offer categories that apply to the product's gender (unisex → all).
    final gender = useValueListenable(selectedGender);
    final selectedIds = useValueListenable(selectedCategoryIds);
    final allCategories = productCategoriesAsync.asData?.value;

    // When gender changes, drop any selected categories that no longer apply
    useEffect(() {
      if (allCategories == null || gender == ProductGender.unisex) return null;
      final validIds = allCategories
          .where((final c) => c.appliesTo(gender))
          .map((final c) => c.id)
          .toSet();
      final current = selectedCategoryIds.value;
      final pruned = current.intersection(validIds);
      if (pruned.length != current.length) {
        selectedCategoryIds.value = pruned;
      }
      return null;
    }, [gender, allCategories]);

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
        const _FieldLabel('性別', required: true),
        ProductGenderSelector(selectedGender: selectedGender),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('分類', required: true),
        productCategoriesAsync.when(
          data: (final allCategories) {
            final categories = gender == ProductGender.unisex
                ? allCategories
                : allCategories.where((final c) => c.appliesTo(gender)).toList();
            return FormField<Set<String>>(
              initialValue: selectedIds,
              validator: (final value) =>
                  AppValidators.validateNonEmpty(value, message: '請選擇至少一種商品類型'),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (final state) {
                if (!setEquals(state.value, selectedIds)) {
                  WidgetsBinding.instance.addPostFrameCallback((final _) {
                    if (state.mounted) state.didChange(selectedIds);
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductCategorySelector(
                      categories: categories,
                      selectedCategoryIds: selectedCategoryIds,
                      hasError: state.hasError,
                      onChanged: (final newIds) {
                        selectedCategoryIds.value = newIds;
                        state.didChange(newIds);
                      },
                    ),
                    if (state.hasError) _ErrorText(state.errorText!),
                  ],
                );
              },
            );
          },
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
