import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';

import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';
import 'package:tryzeon/core/shared/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class AddProductPage extends HookConsumerWidget {
  const AddProductPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productCategoriesAsync = ref.watch(productCategoriesProvider);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final purchaseLinkController = useTextEditingController();

    final selectedImage = useState<File?>(null);
    final selectedCategories = useState<Set<String>>({});
    final sizeControllers = useState<List<Map<String, TextEditingController>>>([]);
    final isLoading = useState(false);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    useEffect(() {
      return () {
        for (final controllers in sizeControllers.value) {
          for (final controller in controllers.values) {
            controller.dispose();
          }
        }
      };
    }, const []);

    void addSizeBlock() {
      final Map<String, TextEditingController> newControllers = {
        'name': TextEditingController(),
      };
      for (final type in MeasurementType.values) {
        newControllers[type.name] = TextEditingController();
        newControllers['${type.name}_offset'] = TextEditingController(text: '0.0');
      }
      sizeControllers.value = [...sizeControllers.value, newControllers];
    }

    void removeSizeBlock(final int index) {
      for (final controller in sizeControllers.value[index].values) {
        controller.dispose();
      }
      final newList = [...sizeControllers.value];
      newList.removeAt(index);
      sizeControllers.value = newList;
    }

    List<ProductSize> buildProductSizes() {
      return sizeControllers.value.map((final controllers) {
        final Map<String, dynamic> measurementsJson = {};
        for (final type in MeasurementType.values) {
          final text = controllers[type.name]?.text;
          final value = text != null && text.isNotEmpty ? double.tryParse(text) : null;

          final offsetText = controllers['${type.name}_offset']?.text;
          final offset = offsetText != null ? double.tryParse(offsetText) : 0.0;

          if (value != null) {
            measurementsJson[type.name] = value;
          }
          measurementsJson['${type.name}_offset'] = offset;
        }

        return ProductSize(
          name: controllers['name']!.text,
          measurements: SizeMeasurements.fromJson(measurementsJson),
        );
      }).toList();
    }

    bool validateProductForm() {
      if (selectedImage.value == null) {
        TopNotification.show(context, message: '請選擇商品圖片', type: NotificationType.warning);
        return false;
      }

      if (selectedCategories.value.isEmpty) {
        TopNotification.show(
          context,
          message: '請至少選擇一種商品類型',
          type: NotificationType.warning,
        );
        return false;
      }

      return true;
    }

    Future<void> handleAddProduct() async {
      if (!formKey.currentState!.validate()) return;
      if (!validateProductForm()) return;

      isLoading.value = true;

      final storeProfile = ref.read(storeProfileProvider).valueOrNull;
      if (storeProfile == null) {
        TopNotification.show(
          context,
          message: '無法獲取店家資訊，請重新登入',
          type: NotificationType.error,
        );
        return;
      }

      final newProduct = Product(
        storeId: storeProfile.id,
        name: nameController.text,
        types: selectedCategories.value,
        price: double.parse(priceController.text),
        purchaseLink: purchaseLinkController.text,
        imagePath: '',
        imageUrl: '',
        sizes: buildProductSizes(),
      );

      final createProductUseCase = ref.read(createProductUseCaseProvider);
      final result = await createProductUseCase(
        product: newProduct,
        image: selectedImage.value!,
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
        TopNotification.show(context, message: '商品新增成功', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    Widget buildTypeSelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '商品類型',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text('(可多選)', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          productCategoriesAsync.when(
            data: (final productCategories) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: productCategories.map((final category) {
                    final isSelected = selectedCategories.value.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (final selected) {
                        final newSet = Set<String>.from(selectedCategories.value);
                        if (selected) {
                          newSet.add(category);
                        } else {
                          newSet.remove(category);
                        }
                        selectedCategories.value = newSet;
                      },
                      backgroundColor: colorScheme.surface,
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      labelStyle: textTheme.labelLarge?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (final error, final stack) => ErrorView(
              onRetry: () => ref.refresh(productCategoriesProvider),
              isCompact: true,
            ),
          ),
        ],
      );
    }

    void updateOffset(final TextEditingController controller, final double delta) {
      final currentValue = double.tryParse(controller.text) ?? 0.0;
      final newValue = (currentValue + delta).clamp(0.0, 100.0); // 限制 offset 不小於 0

      // 處理浮點數精度問題
      controller.text = newValue.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }

    Widget buildSizeInputs() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.straighten_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '尺寸列表',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: addSizeBlock,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新增尺寸'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sizeControllers.value.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  '尚未新增尺寸',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...List.generate(sizeControllers.value.length, (final index) {
              final controllers = sizeControllers.value[index];
              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '尺寸 ${index + 1}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              onPressed: () => removeSizeBlock(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['name'],
                          style: textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: '尺寸名稱 (如: S, M, XL)',
                            labelStyle: textTheme.bodyMedium,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainer,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          validator: AppValidators.validateSizeName,
                        ),
                        const SizedBox(height: 16),
                        ...MeasurementType.values.map((final type) {
                          final valueController = controllers[type.name]!;
                          final offsetController = controllers['${type.name}_offset']!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                // 測量值輸入
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: valueController,
                                    style: textTheme.bodyLarge,
                                    decoration: InputDecoration(
                                      labelText: type.label,
                                      labelStyle: textTheme.bodyMedium,
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    validator: AppValidators.validateMeasurement,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Offset 控制
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '誤差範圍 (±)',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Material(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  updateOffset(offsetController, -0.5),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                bottomLeft: Radius.circular(8),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: const Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.symmetric(
                                                  horizontal: BorderSide(
                                                    color: colorScheme.outline.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              child: AnimatedBuilder(
                                                animation: offsetController,
                                                builder: (final context, final child) {
                                                  return Text(
                                                    offsetController.text,
                                                    textAlign: TextAlign.center,
                                                    style: textTheme.bodyMedium,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Material(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  updateOffset(offsetController, 0.5),
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                bottomRight: Radius.circular(8),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: const Icon(Icons.add, size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('新增商品', style: textTheme.headlineMedium),
                          Text('新增商品到您的店家', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('商品圖片', style: textTheme.titleSmall),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                final image = await ImagePickerHelper.pickImage(context);
                                if (image != null) {
                                  selectedImage.value = image;
                                }
                              },
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: selectedImage.value == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 40,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '點擊選擇圖片',
                                            style: textTheme.labelLarge?.copyWith(
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          selectedImage.value!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('商品資訊', style: textTheme.titleSmall),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nameController,
                              style: textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: '商品名稱',
                                labelStyle: textTheme.bodyMedium,
                                prefixIcon: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainer,
                              ),
                              validator: AppValidators.validateProductName,
                            ),
                            const SizedBox(height: 12),
                            buildTypeSelector(),
                            const SizedBox(height: 16),
                            buildSizeInputs(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: priceController,
                              style: textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: '價格',
                                labelStyle: textTheme.bodyMedium,
                                prefixIcon: Icon(
                                  Icons.attach_money_rounded,
                                  color: colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainer,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: AppValidators.validatePrice,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: purchaseLinkController,
                              style: textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: '購買連結',
                                hintText: 'https://...',
                                labelStyle: textTheme.bodyMedium,
                                prefixIcon: Icon(
                                  Icons.link_rounded,
                                  color: colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainer,
                              ),
                              keyboardType: TextInputType.url,
                              validator: AppValidators.validateUrl,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isLoading.value
                              ? colorScheme.outline
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isLoading.value
                              ? []
                              : [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading.value ? null : handleAddProduct,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: isLoading.value
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '新增商品',
                                          style: textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
