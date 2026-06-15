import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_form_layout.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class AddProductPage extends HookConsumerWidget {
  const AddProductPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formData = useProductForm();
    final sizeManager = useProductSizeManager();
    final isSaving = useState(false);
    final productCategoriesAsync = ref.watch(productCategoriesProvider);

    Future<void> addProduct() async {
      if (!formData.validate(context)) return;

      isSaving.value = true;

      final storeProfile = await ref.read(storeProfileProvider.future);
      if (!context.mounted) return;

      if (storeProfile == null) {
        TopNotification.show(context, message: '無法獲取店家資訊，請重新登入');
        isSaving.value = false;
        return;
      }

      final createProductUseCase = ref.read(createProductUseCaseProvider);
      final result = await createProductUseCase(
        formData.toCreateProductParams(
          storeId: storeProfile.id,
          sizes: sizeManager.toCreateProductSizeParams(),
        ),
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
        title: const Text('新增商品'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.smMd),
            child: TextButton(
              onPressed: isSaving.value ? null : addProduct,
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
        child: ProductFormLayout(
          formData: formData,
          sizeManager: sizeManager,
          productCategoriesAsync: productCategoriesAsync,
          onRetryCategories: () => ref.invalidate(productCategoriesProvider),
          onPickImage: (final remainingCount) async {
            return ImagePickerHelper.pickImages(context, maxImages: remainingCount);
          },
        ),
      ),
    );
  }
}
