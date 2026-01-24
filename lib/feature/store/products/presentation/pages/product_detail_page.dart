import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/core/domain/entities/size_measurements.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/providers/providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/providers/providers.dart';
import 'package:typed_result/typed_result.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productCategoriesAsync = ref.watch(productCategoriesProvider);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController(text: product.name);
    final priceController = useTextEditingController(text: product.price.toString());
    final purchaseLinkController = useTextEditingController(text: product.purchaseLink);
    final newImage = useState<File?>(null);
    final isLoading = useState(false);
    final selectedCategories = useState<Set<String>>(Set<String>.from(product.types));
    final sizeEntries = useState<List<_SizeEntry>>([]);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    useEffect(() {
      final entries = <_SizeEntry>[];
      if (product.sizes != null) {
        for (final size in product.sizes!) {
          entries.add(_SizeEntry.fromProductSize(size));
        }
      }
      sizeEntries.value = entries;

      return () {
        for (final entry in sizeEntries.value) {
          entry.dispose();
        }
      };
    }, const []);

    Future<void> deleteProduct() async {
      final confirm = await ConfirmationDialog.show(
        context: context,
        title: '刪除商品',
        content: '確定要刪除「${product.name}」嗎?',
        confirmText: '刪除',
      );

      if (confirm != true) return;

      isLoading.value = true;

      final deleteProductUseCase = ref.read(deleteProductUseCaseProvider);
      final result = await deleteProductUseCase(product);

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        TopNotification.show(context, message: '商品刪除成功', type: NotificationType.success);
        Navigator.pop(context, true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    Future<void> updateProduct() async {
      if (!formKey.currentState!.validate()) return;

      if (selectedCategories.value.isEmpty) {
        TopNotification.show(
          context,
          message: '請至少選擇一個類型',
          type: NotificationType.warning,
        );
        return;
      }

      isLoading.value = true;

      final targetProduct = Product(
        storeId: product.storeId,
        name: nameController.text,
        types: selectedCategories.value,
        price: double.parse(priceController.text),
        imagePath: product.imagePath,
        imageUrl: product.imageUrl,
        id: product.id,
        purchaseLink: purchaseLinkController.text,
        sizes: sizeEntries.value.map((final e) => e.toProductSize(product.id!)).toList(),
      );

      final updateProductUseCase = ref.read(updateProductUseCaseProvider);
      final result = await updateProductUseCase(
        original: product,
        target: targetProduct,
        newImage: newImage.value,
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
        TopNotification.show(context, message: '商品更新成功', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    void addSize() {
      sizeEntries.value = [...sizeEntries.value, _SizeEntry()];
    }

    void removeSize(final int index) {
      sizeEntries.value[index].dispose();
      final newList = [...sizeEntries.value];
      newList.removeAt(index);
      sizeEntries.value = newList;
    }

    Widget buildTextField({
      required final TextEditingController controller,
      required final String label,
      required final IconData icon,
      final TextInputType? keyboardType,
      final String? hintText,
      final Color? filledColor,
      final bool isDense = false,
      final String? Function(String?)? validator,
      final List<TextInputFormatter>? inputFormatters,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: textTheme.bodyMedium,
          prefixIcon: Icon(icon, color: colorScheme.outline, size: 20),
          filled: true,
          fillColor: filledColor ?? colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      );
    }

    void updateOffset(final TextEditingController controller, final double delta) {
      final currentValue = double.tryParse(controller.text) ?? 0.0;
      final newValue = (currentValue + delta).clamp(0.0, 100.0);
      controller.text = newValue.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }

    Widget buildMeasurementField(
      final TextEditingController valueController,
      final TextEditingController offsetController,
      final String label,
      final IconData icon,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: buildTextField(
                controller: valueController,
                label: label,
                icon: icon,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                filledColor: Theme.of(context).colorScheme.surface,
                isDense: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: AppValidators.validateMeasurement,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '誤差範圍 (±)',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
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
                          onTap: () => updateOffset(offsetController, -0.5),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.1),
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
                          onTap: () => updateOffset(offsetController, 0.5),
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
    }

    Widget buildSizeList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('尺寸詳細資訊', style: textTheme.titleMedium),
              TextButton.icon(
                onPressed: addSize,
                icon: const Icon(Icons.add),
                label: const Text('新增尺寸'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sizeEntries.value.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Center(
                child: Text(
                  '暫無尺寸資訊',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                ),
              ),
            ),
          ...sizeEntries.value.asMap().entries.map((final entry) {
            final index = entry.key;
            final sizeEntry = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              color: colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: sizeEntry.nameController,
                            label: '尺寸名稱 (如: S, M)',
                            icon: Icons.label_outline,
                            filledColor: colorScheme.surface,
                            validator: AppValidators.validateSizeName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: colorScheme.error,
                          onPressed: () => removeSize(index),
                          tooltip: '刪除此尺寸',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: MeasurementType.values.map((final type) {
                        return buildMeasurementField(
                          sizeEntry.measurementControllers[type]!,
                          sizeEntry.offsetControllers[type]!,
                          type.label,
                          type.icon,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    Widget buildTypeSelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, color: colorScheme.outline, size: 20),
              const SizedBox(width: 8),
              Text('商品類型', style: textTheme.bodyMedium),
              const SizedBox(width: 8),
              Text('(可多選)', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          productCategoriesAsync.when(
            data: (final categories) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((final category) {
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
                      labelStyle: textTheme.bodyMedium?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
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

    return Scaffold(
      appBar: AppBar(
        title: Text('商品資訊', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.onSurfaceVariant),
            onPressed: deleteProduct,
            tooltip: '刪除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final image = await ImagePickerHelper.pickImage(context);
                  if (image != null) {
                    newImage.value = image;
                  }
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant, width: 1),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: newImage.value != null
                            ? Image.file(
                                newImage.value!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              )
                            : CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                cacheKey: product.imagePath,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                placeholder: (final context, final url) => Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.outline,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (final context, final url, final error) =>
                                    Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: colorScheme.error,
                                      ),
                                    ),
                              ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.onInverseSurface,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              buildTextField(
                controller: nameController,
                label: '商品名稱',
                icon: Icons.inventory_2_outlined,
                validator: AppValidators.validateProductName,
              ),
              const SizedBox(height: 16),

              buildTypeSelector(),
              const SizedBox(height: 16),

              buildTextField(
                controller: priceController,
                label: '價格',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: AppValidators.validatePrice,
              ),
              const SizedBox(height: 16),

              buildTextField(
                controller: purchaseLinkController,
                label: '購買連結',
                icon: Icons.link,
                keyboardType: TextInputType.url,
                hintText: 'https://...',
                validator: AppValidators.validateUrl,
              ),
              const SizedBox(height: 24),

              buildSizeList(),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading.value ? null : updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          '儲存變更',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
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

class _SizeEntry {
  _SizeEntry({this.id, final String name = '', final SizeMeasurements? measurements})
    : nameController = TextEditingController(text: name) {
    for (final type in MeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: measurements?.getValue(type)?.toString() ?? '',
      );
      offsetControllers[type] = TextEditingController(
        text: measurements?.getOffset(type)?.toString() ?? '0.0',
      );
    }
  }

  factory _SizeEntry.fromProductSize(final ProductSize size) {
    return _SizeEntry(id: size.id, name: size.name, measurements: size.measurements);
  }

  ProductSize toProductSize(final String productId) {
    final Map<String, dynamic> measurementsJson = {};
    for (final type in MeasurementType.values) {
      final valueText = measurementControllers[type]?.text;
      final value = valueText != null ? double.tryParse(valueText) : null;

      final offsetText = offsetControllers[type]?.text;
      final offset = offsetText != null ? double.tryParse(offsetText) : 0.0;

      if (value != null) {
        measurementsJson[type.key] = value;
      }
      measurementsJson['${type.key}_offset'] = offset;
    }

    return ProductSize(
      id: id,
      productId: productId,
      name: nameController.text,
      measurements: SizeMeasurements.fromJson(measurementsJson),
    );
  }

  final String? id;
  final TextEditingController nameController;
  final Map<MeasurementType, TextEditingController> measurementControllers = {};
  final Map<MeasurementType, TextEditingController> offsetControllers = {};

  void dispose() {
    nameController.dispose();
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
    for (final controller in offsetControllers.values) {
      controller.dispose();
    }
  }
}
