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
import 'package:tryzeon/feature/store/products/presentation/hooks/use_size_voice_input.dart';
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
    final messenger = ScaffoldMessenger.of(context);
    final voiceInput = useSizeVoiceInput(
      ref: ref,
      sizeManager: sizeManager,
      onApplied: (final count) =>
          messenger.showSnackBar(SnackBar(content: Text('已新增 $count 筆尺寸，請檢查數字'))),
      onError: (final message) =>
          messenger.showSnackBar(SnackBar(content: Text(message))),
      onPermissionDenied: () =>
          messenger.showSnackBar(const SnackBar(content: Text('需要麥克風權限才能語音輸入，請至系統設定開啟'))),
    );
    final isSaving = useState(false);
    final productCategoriesAsync = ref.watch(productCategoriesProvider);

    final isAnalyzing = useState(false);
    final analyzedPath = useRef<String?>(null);
    final advancedController = useMemoized(ExpansibleController.new);

    // Analyze the main (first) image once it is added, and pre-fill empty
    // fields. Runs once per distinct main-image file; failures degrade to a
    // no-op (the usecase returns an empty result).
    final newFiles = formData.newImageFiles;
    final mainImageFile = newFiles.isEmpty ? null : newFiles.first;
    useEffect(() {
      final file = mainImageFile;
      if (file == null || analyzedPath.value == file.path) return null;
      analyzedPath.value = file.path;
      isAnalyzing.value = true;
      Future<void>(() async {
        final result = await ref.read(analyzeProductImageUseCaseProvider)(file);
        if (!context.mounted) return;

        formData.applyAnalysis(result);

        if (result.hasAdvancedFields) advancedController.expand();
        isAnalyzing.value = false;
      });
      return null;
    }, [mainImageFile]);

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
          isAnalyzing: isAnalyzing.value,
          advancedController: advancedController,
          voiceStatus: voiceInput.status,
          onVoicePressed: voiceInput.toggle,
          onPickImage: (final remainingCount) async {
            return ImagePickerHelper.pickImages(context, maxImages: remainingCount);
          },
        ),
      ),
    );
  }
}
