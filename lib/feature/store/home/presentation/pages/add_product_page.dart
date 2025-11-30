import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/services/product_type_service.dart';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/product_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController purchaseLinkController = TextEditingController();

  File? selectedImage;
  List<String> productTypes = [];
  Set<String> selectedTypes = {};
  List<Map<String, TextEditingController>> sizeControllers = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProductTypes();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    purchaseLinkController.dispose();
    for (final controllers in sizeControllers) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _addSizeBlock() {
    setState(() {
      final Map<String, TextEditingController> newControllers = {
        'name': TextEditingController(),
      };
      for (final type in MeasurementType.values) {
        newControllers[type.name] = TextEditingController();
      }
      sizeControllers.add(newControllers);
    });
  }

  void _removeSizeBlock(final int index) {
    setState(() {
      for (final controller in sizeControllers[index].values) {
        controller.dispose();
      }
      sizeControllers.removeAt(index);
    });
  }

  List<ProductSize> _buildProductSizes() {
    return sizeControllers.map((final controllers) {
      final Map<MeasurementType, double?> measurementsMap = {};
      for (final type in MeasurementType.values) {
        final text = controllers[type.name]?.text;
        measurementsMap[type] = text != null && text.isNotEmpty
            ? double.tryParse(text)
            : null;
      }

      return ProductSize(
        name: controllers['name']!.text,
        measurements: BodyMeasurements.fromTypeMap(measurementsMap),
      );
    }).toList();
  }

  Future<void> _loadProductTypes() async {
    final result = await ProductTypeService.getProductTypesList();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        productTypes = result.data!;
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '載入商品類型失敗',
        type: NotificationType.error,
      );
    }
  }

  bool _validateProductForm() {
    if (selectedImage == null ||
        nameController.text.isEmpty ||
        selectedTypes.isEmpty ||
        priceController.text.isEmpty) {
      TopNotification.show(
        context,
        message: '請填寫完整資料',
        type: NotificationType.warning,
      );
      return false;
    }

    final price = int.tryParse(priceController.text);
    if (price == null) {
      TopNotification.show(
        context,
        message: '請輸入有效的價格',
        type: NotificationType.warning,
      );
      return false;
    }

    return true;
  }

  Future<void> _handleAddProduct() async {
    if (!_validateProductForm()) return;

    setState(() {
      isLoading = true;
    });

    final result = await ProductService.createProduct(
      name: nameController.text,
      types: selectedTypes.toList(),
      price: int.parse(priceController.text),
      purchaseLink: purchaseLinkController.text,
      productImage: selectedImage!,
      sizes: _buildProductSizes(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result.isSuccess) {
      Navigator.pop(context, true);
      TopNotification.show(
        context,
        message: '商品新增成功',
        type: NotificationType.success,
      );
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '商品新增失敗,請稍後再試',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 自訂 AppBar
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

              // 內容
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // 圖片上傳卡片
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
                              final image = await ImagePickerHelper.pickImage(
                                context,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedImage = image;
                                });
                              }
                            },
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.1),
                                    colorScheme.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: selectedImage == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        selectedImage!,
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

                    // 商品資訊卡片
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

                          // 商品名稱
                          TextField(
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
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
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
                          ),

                          const SizedBox(height: 12),

                          // 商品類型（多選）
                          _buildTypeSelector(),

                          const SizedBox(height: 16),

                          // 尺寸資訊 (列表 + 新增按鈕)
                          _buildSizeInputs(),

                          const SizedBox(height: 16),

                          // 價格
                          TextField(
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
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
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
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 12),

                          // 購買連結
                          TextField(
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
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 新增按鈕
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isLoading
                            ? LinearGradient(
                                colors: [
                                  colorScheme.outline,
                                  colorScheme.outlineVariant,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isLoading ? null : _handleAddProduct,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: isLoading
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '商品類型',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text('(可多選)', style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: productTypes.map((final type) {
              final isSelected = selectedTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (final selected) {
                  setState(() {
                    if (selected) {
                      selectedTypes.add(type);
                    } else {
                      selectedTypes.remove(type);
                    }
                  });
                },
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
        ),
      ],
    );
  }

  Widget _buildSizeInputs() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '尺寸列表',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _addSizeBlock,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新增尺寸'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sizeControllers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
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
          ...List.generate(sizeControllers.length, (final index) {
            final controllers = sizeControllers[index];
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
                            onPressed: () => _removeSizeBlock(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 尺寸名稱
                      TextField(
                        controller: controllers['name'],
                        style: textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: '尺寸名稱 (如: S, M, XL)',
                          labelStyle: textTheme.bodySmall,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 12),
                      // 身體測量欄位
                      ...MeasurementType.values.map((final type) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextField(
                            controller: controllers[type.name],
                            style: textTheme.bodyMedium,
                            decoration: InputDecoration(
                              labelText: type.label,
                              labelStyle: textTheme.bodySmall,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
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
}
