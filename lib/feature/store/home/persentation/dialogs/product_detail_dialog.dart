import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/services/product_type_service.dart';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/product_service.dart';

class ProductDetailDialog extends StatefulWidget {
  const ProductDetailDialog({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController purchaseLinkController;
  File? newImage;
  bool isLoading = false;

  // 衣服種類選項
  List<String> clothingTypes = [];
  Set<String> selectedTypes = {};

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    purchaseLinkController = TextEditingController(
      text: widget.product.purchaseLink,
    );
    selectedTypes = Set<String>.from(widget.product.types);
    _loadProductTypes();
  }

  Future<void> _loadProductTypes() async {
    final result = await ProductTypeService.getProductTypesList();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        clothingTypes = result.data!;
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '載入商品類型失敗',
        type: NotificationType.error,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    purchaseLinkController.dispose();
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
      Navigator.pop(context, true);
      TopNotification.show(
        context,
        message: '商品刪除成功',
        type: NotificationType.success,
      );
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '商品刪除失敗，請稍後再試',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _updateProduct() async {
    final price = int.tryParse(priceController.text);
    if (price == null) {
      TopNotification.show(
        context,
        message: '請輸入有效的價格',
        type: NotificationType.warning,
      );
      return;
    }

    if (selectedTypes.isEmpty) {
      TopNotification.show(
        context,
        message: '請至少選擇一個類型',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await ProductService.updateProduct(
      productId: widget.product.id!,
      name: nameController.text,
      types: selectedTypes.toList(), // 改為 types 傳遞陣列
      price: price,
      purchaseLink: purchaseLinkController.text,
      currentFilePath: widget.product.imagePath,
      newImageFile: newImage,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result.isSuccess) {
      Navigator.pop(context, true);
      TopNotification.show(
        context,
        message: '商品更新成功',
        type: NotificationType.success,
      );
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '商品更新失敗，請稍後再試',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題列 - 固定在頂部
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('商品資訊', style: textTheme.titleLarge)),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: _deleteProduct,
                    tooltip: '刪除',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '關閉',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
            ),

            // 可滾動內容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 圖片區域
                    GestureDetector(
                      onTap: () async {
                        final image = await ImagePickerHelper.pickImage(
                          context,
                        );
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
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
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
                                      future: widget.product.loadImage(),
                                      builder: (final context, final snapshot) {
                                        final result = snapshot.data;
                                        if (result != null &&
                                            result.isSuccess) {
                                          return Image.file(
                                            result.file!,
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
                                        if (result != null &&
                                            !result.isSuccess) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (mounted) {
                                                  TopNotification.show(
                                                    context,
                                                    message:
                                                        result.errorMessage ??
                                                        '載入圖片失敗',
                                                    type:
                                                        NotificationType.error,
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
                    ),
                    const SizedBox(height: 16),

                    _buildTypeSelector(),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: priceController,
                      label: '價格',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: purchaseLinkController,
                      label: '購買連結',
                      icon: Icons.link,
                      keyboardType: TextInputType.url,
                      hintText: 'https://...',
                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required final TextEditingController controller,
    required final String label,
    required final IconData icon,
    final TextInputType? keyboardType,
    final String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: textTheme.bodyMedium,
        prefixIcon: Icon(icon, color: colorScheme.outline, size: 20),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
            children: clothingTypes.map((final type) {
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
                        : colorScheme.outlineVariant,
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
