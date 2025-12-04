import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/feature/store/home/data/product_service.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/product_type_service.dart';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late Future<Result<File>> productImage;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController purchaseLinkController;
  File? newImage;
  bool isLoading = false;

  // 衣服種類選項
  List<String> clothesTypes = [];
  Set<String> selectedTypes = {};

  // 尺寸列表
  final List<_SizeEntry> _sizeEntries = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    purchaseLinkController = TextEditingController(text: widget.product.purchaseLink);
    selectedTypes = Set<String>.from(widget.product.types);
    productImage = widget.product.loadImage();
    _loadProductTypes();

    // 從商品資料中載入尺寸（因為 getProducts 已經包含了 product_sizes）
    if (widget.product.sizes != null) {
      for (final size in widget.product.sizes!) {
        _sizeEntries.add(_SizeEntry.fromProductSize(size));
      }
    }
  }

  Future<void> _loadProductTypes() async {
    final result = await ProductTypeService.getProductTypes();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        clothesTypes = result.data!;
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    purchaseLinkController.dispose();
    for (final entry in _sizeEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _deleteProduct() async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: '刪除商品',
      content: '確定要刪除「${widget.product.name}」嗎?',
      confirmText: '刪除',
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    final result = await ProductService.deleteProduct(widget.product);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result.isSuccess) {
      TopNotification.show(context, message: '商品刪除成功', type: NotificationType.success);
      Navigator.pop(context, true);
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTypes.isEmpty) {
      TopNotification.show(context, message: '請至少選擇一個類型', type: NotificationType.warning);
      return;
    }

    setState(() {
      isLoading = true;
    });

    // 準備目標商品資料
    final targetProduct = Product(
      storeId: widget.product.storeId,
      name: nameController.text,
      types: selectedTypes,
      price: int.parse(priceController.text),
      imagePath: widget.product.imagePath,
      id: widget.product.id,
      purchaseLink: purchaseLinkController.text,
      sizes: _sizeEntries.map((final e) => e.toProductSize(widget.product.id!)).toList(),
    );

    final result = await ProductService.updateProduct(
      original: widget.product,
      target: targetProduct,
      newImage: newImage,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result.isSuccess) {
      Navigator.pop(context, true);
      TopNotification.show(context, message: '商品更新成功', type: NotificationType.success);
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  void _addSize() {
    setState(() {
      _sizeEntries.add(_SizeEntry());
    });
  }

  void _removeSize(final int index) {
    setState(() {
      _sizeEntries[index].dispose();
      _sizeEntries.removeAt(index);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('商品資訊', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.onSurfaceVariant),
            onPressed: _deleteProduct,
            tooltip: '刪除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 圖片區域
              GestureDetector(
                onTap: () async {
                  final image = await ImagePickerHelper.pickImage(context);
                  if (image != null) {
                    setState(() {
                      newImage = image;
                    });
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
                        child: newImage != null
                            ? Image.file(
                                newImage!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              )
                            : FutureBuilder(
                                future: productImage,
                                builder: (final context, final snapshot) {
                                  final result = snapshot.data;
                                  if (result != null && result.isSuccess) {
                                    return Image.file(
                                      result.data!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorBuilder:
                                          (
                                            final context,
                                            final error,
                                            final stackTrace,
                                          ) => Center(
                                            child: Icon(
                                              Icons.image_outlined,
                                              size: 48,
                                              color: colorScheme.outline,
                                            ),
                                          ),
                                    );
                                  }
                                  if (result != null && !result.isSuccess) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        TopNotification.show(
                                          context,
                                          message: result.errorMessage!,
                                          type: NotificationType.error,
                                        );
                                      }
                                    });
                                    return Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: colorScheme.error,
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.outline,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
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

              // 表單欄位
              _buildTextField(
                controller: nameController,
                label: '商品名稱',
                icon: Icons.inventory_2_outlined,
                validator: (final value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入商品名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTypeSelector(),
              const SizedBox(height: 16),

              _buildTextField(
                controller: priceController,
                label: '價格',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (final value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入價格';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: purchaseLinkController,
                label: '購買連結',
                icon: Icons.link,
                keyboardType: TextInputType.url,
                hintText: 'https://...',
                validator: (final value) {
                  if (value != null && value.isNotEmpty) {
                    // Optional: Check for valid URL format if needed
                    if (!Uri.parse(value).isAbsolute) {
                      return '請輸入有效的網址';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 尺寸編輯區
              _buildSizeList(),
              const SizedBox(height: 24),

              // 儲存按鈕
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
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

  Widget _buildSizeList() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('尺寸詳細資訊', style: textTheme.titleMedium),
            TextButton.icon(
              onPressed: _addSize,
              icon: const Icon(Icons.add),
              label: const Text('新增尺寸'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_sizeEntries.isEmpty)
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
        ..._sizeEntries.asMap().entries.map((final entry) {
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
                        child: _buildTextField(
                          controller: sizeEntry.nameController,
                          label: '尺寸名稱 (如: S, M)',
                          icon: Icons.label_outline,
                          filledColor: colorScheme.surface,
                          validator: (final value) {
                            if (value == null || value.trim().isEmpty) {
                              return '請輸入尺寸名稱';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: colorScheme.error,
                        onPressed: () => _removeSize(index),
                        tooltip: '刪除此尺寸',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: MeasurementType.values.map((final type) {
                      return _buildMeasurementField(
                        sizeEntry.measurementControllers[type]!,
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

  Widget _buildMeasurementField(
    final TextEditingController controller,
    final String label,
    final IconData icon,
  ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48 - 32 - 12) / 2,
      child: _buildTextField(
        controller: controller,
        label: label,
        icon: icon,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        filledColor: Theme.of(context).colorScheme.surface,
        isDense: true,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        validator: (final value) {
          if (value != null && value.isNotEmpty) {
            if (double.tryParse(value) == null) {
              return '請輸入有效數字';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

  Widget _buildTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        Container(
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
            children: clothesTypes.map((final type) {
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
                labelStyle: textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SizeEntry {
  _SizeEntry({this.id, final String name = '', final BodyMeasurements? measurements})
    : nameController = TextEditingController(text: name) {
    for (final type in MeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: measurements?[type]?.toString() ?? '',
      );
    }
  }

  factory _SizeEntry.fromProductSize(final ProductSize size) {
    return _SizeEntry(id: size.id, name: size.name, measurements: size.measurements);
  }

  ProductSize toProductSize(final String productId) {
    final Map<String, dynamic> measurementsJson = {};
    for (final entry in measurementControllers.entries) {
      final value = double.tryParse(entry.value.text);
      if (value != null) {
        measurementsJson[entry.key.key] = value;
      }
    }

    return ProductSize(
      id: id,
      productId: productId,
      name: nameController.text,
      measurements: BodyMeasurements.fromJson(measurementsJson),
    );
  }

  final String? id;
  final TextEditingController nameController;
  final Map<MeasurementType, TextEditingController> measurementControllers = {};

  void dispose() {
    nameController.dispose();
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
  }
}
