import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_size_voice_input.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_danger_zone.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_form_layout.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:typed_result/typed_result.dart';

class EditProductPage extends ConsumerWidget {
  const EditProductPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final product = productAsync.hasValue ? productAsync.requireValue : null;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('編輯商品')),
        body: productAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ErrorView(
                message: productAsync.error.displayMessage(context),
                onRetry: () => ref.invalidate(productByIdProvider(productId)),
              ),
      );
    }

    return _EditProductContent(product: product);
  }
}

class _EditProductContent extends HookConsumerWidget {
  const _EditProductContent({required this.product});

  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formData = useProductForm(initialProduct: product);
    final sizeManager = useProductSizeManager(initialSizes: product.sizes);
    final messenger = ScaffoldMessenger.of(context);
    final voiceInput = useSizeVoiceInput(
      ref: ref,
      sizeManager: sizeManager,
      onApplied: (final count) =>
          messenger.showSnackBar(SnackBar(content: Text('已新增 $count 筆尺寸，請檢查數字'))),
      onError: (final message) =>
          messenger.showSnackBar(SnackBar(content: Text(message))),
      onPermissionDenied: () => messenger.showSnackBar(
        const SnackBar(
          content: Text('需要麥克風權限才能語音輸入'),
          action: SnackBarAction(label: '前往設定', onPressed: openAppSettings),
        ),
      ),
    );
    final isSaving = useState(false);
    final isDeleting = useState(false);
    final productCategoriesAsync = ref.watch(productCategoriesProvider);

    Future<void> deleteProduct() async {
      final dialogResult = await showAppOkCancelDialog(
        context: context,
        title: '刪除商品',
        message: '確定要刪除「${product.name}」嗎?\n此操作無法復原。',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (dialogResult != OkCancelResult.ok) return;

      isDeleting.value = true;

      final deleteProductUseCase = ref.read(deleteProductUseCaseProvider);
      final result = await deleteProductUseCase(product);

      if (!context.mounted) return;

      isDeleting.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        context.pop(true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
    }

    Future<void> updateProduct() async {
      if (!formData.validate(context)) return;

      isSaving.value = true;

      final deltas = sizeManager.calculateDeltas(product.id, product.sizes);

      final updateProductUseCase = ref.read(updateProductUseCaseProvider);
      final result = await updateProductUseCase(
        original: product,
        params: formData.toUpdateProductParams(productId: product.id, deltas: deltas),
      );

      if (!context.mounted) return;

      isSaving.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        context.pop(true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯商品'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.smMd),
            child: TextButton(
              onPressed: (isSaving.value || isDeleting.value) ? null : updateProduct,
              child: isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
                    )
                  : const Text('儲存'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductFormLayout(
              formData: formData,
              sizeManager: sizeManager,
              productCategoriesAsync: productCategoriesAsync,
              onRetryCategories: () => ref.invalidate(productCategoriesProvider),
              voiceStatus: voiceInput.status,
              onVoicePressed: voiceInput.toggle,
              onPickImage: (final remainingCount) async {
                return ImagePickerHelper.pickImages(context, maxImages: remainingCount);
              },
            ),
            ProductDangerZone(
              onDelete: deleteProduct,
              isSaving: isSaving.value,
              isDeleting: isDeleting.value,
            ),
          ],
        ),
      ),
    );
  }
}
