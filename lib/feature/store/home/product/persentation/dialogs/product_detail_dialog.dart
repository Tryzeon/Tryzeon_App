import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/services/product_type_service.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import '../../data/product_service.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;

  const ProductDetailDialog({super.key, required this.product});

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
    priceController = TextEditingController(text: widget.product.price.toString());
    purchaseLinkController = TextEditingController(text: widget.product.purchaseLink);
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
      types: selectedTypes.toList(),  // 改為 types 傳遞陣列
      price: price,
      purchaseLink: purchaseLinkController.text,
      currentFilePath: widget.product.imagePath,
      newImageFile: newImage
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '商品資訊',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[700], size: 22),
                    onPressed: _deleteProduct,
                    tooltip: '刪除',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[700], size: 22),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '關閉',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
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
                                      builder: (context, snapshot) {
                                        final result = snapshot.data;
                                        if (result != null && result.isSuccess) {
                                          return Image.file(
                                            result.file!,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 48,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                          );
                                        }
                                        if (result != null && !result.isSuccess) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (mounted) {
                                              TopNotification.show(
                                                context,
                                                message: result.errorMessage ?? '載入圖片失敗',
                                                type: NotificationType.error,
                                              );
                                            }
                                          });
                                          return Center(
                                            child: Icon(
                                              Icons.error_outline,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.grey[400],
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
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
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
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '儲存變更',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              '商品類型',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(可多選)',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: clothingTypes.map((type) {
              final isSelected = selectedTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedTypes.add(type);
                    } else {
                      selectedTypes.remove(type);
                    }
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: Colors.black87,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.black87 : Colors.grey[300]!,
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