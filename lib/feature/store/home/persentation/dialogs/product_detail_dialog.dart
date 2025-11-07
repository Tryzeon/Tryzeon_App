import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:tryzeon/shared/models/product_model.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';
import 'package:tryzeon/feature/personal/shop/data/type_filter_service.dart';
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
  String? selectedType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    purchaseLinkController = TextEditingController(text: widget.product.purchaseLink);
    selectedType = widget.product.type;
    _loadProductTypes();
  }

  Future<void> _loadProductTypes() async {
    final types = await ProductTypeService.getProductTypesList();
    if (mounted) {
      setState(() {
        clothingTypes = types;
      });
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
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 圖示
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 28,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 16),

                // 標題
                Text(
                  '刪除商品',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // 說明文字
                Text(
                  '確定要刪除「${widget.product.name}」嗎？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '此操作無法復原',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),

                // 按鈕組
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '刪除',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    final success = await ProductService.deleteProduct(widget.product);

    setState(() {
      isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
        TopNotification.show(
          context,
          message: '商品刪除成功',
          type: NotificationType.success,
        );
      }
    } else {
      if (mounted) {
        TopNotification.show(
          context,
          message: '商品刪除失敗，請稍後再試',
          type: NotificationType.error,
        );
      }
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

    setState(() {
      isLoading = true;
    });

    final success = await ProductService.updateProduct(
      productId: widget.product.id!,
      name: nameController.text,
      type: selectedType!,
      price: price,
      purchaseLink: purchaseLinkController.text,
      currentFilePath: widget.product.imagePath,
      newImageFile: newImage
    );

    setState(() {
      isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
        TopNotification.show(
          context,
          message: '商品更新成功',
          type: NotificationType.success,
        );
      }
    } else {
      if (mounted) {
        TopNotification.show(
          context,
          message: '商品更新失敗，請稍後再試',
          type: NotificationType.error,
        );
      }
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
                                  : FutureBuilder<File?>(
                                      future: FileCacheService.getFile(widget.product.imagePath),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data != null) {
                                          return Image.file(
                                            snapshot.data!,
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

                    _buildDropdown(context),
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

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedType,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: '衣服種類',
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        prefixIcon: Icon(Icons.category_outlined, color: Colors.grey[600], size: 20),
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
      items: clothingTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedType = newValue;
        });
      },
    );
  }
}