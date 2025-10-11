import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tryzeon/shared/component/image_picker_helper.dart';
import 'package:tryzeon/shared/models/product_model.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';
import '../../../data/product_service.dart';

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
  bool isEditing = false;
  bool isLoading = false;
  
  // 衣服種類選項
  final List<String> clothingTypes = ['上衣', '褲子', '裙子', '外套', '鞋子', '配件', '其他'];
  String? selectedType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    purchaseLinkController = TextEditingController(text: widget.product.purchaseLink);
    selectedType = widget.product.type;
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: Text('確定要刪除「${widget.product.name}」嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
              ),
              child: const Text('刪除', style: TextStyle(color: Colors.white)),
            ),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品刪除成功')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品刪除失敗，請稍後再試')),
        );
      }
    }
  }

  Future<void> _updateProduct() async {
    final price = double.tryParse(priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的價格')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品更新成功')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品更新失敗，請稍後再試')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '商品資訊',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _deleteProduct,
                          tooltip: '刪除商品',
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              isEditing = true;
                            });
                          },
                          tooltip: '編輯商品',
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: isEditing
                    ? () async {
                        final image = await ImagePickerHelper.pickImage(context);
                        if (image != null) {
                          setState(() {
                            newImage = image;
                          });
                        }
                      }
                    : null,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CCC8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: newImage != null
                        ? Image.file(
                            newImage!,
                            fit: BoxFit.contain,
                          )
                        : FutureBuilder<File?>(
                            future: FileCacheService.getFile(widget.product.imagePath),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.file(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported),
                                );
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: '商品名稱',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: '衣服種類',
                  border: OutlineInputBorder(),
                ),
                items: clothingTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: isEditing ? (String? newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                } : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '價格',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purchaseLinkController,
                enabled: isEditing,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '購買連結',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                          newImage = null;
                          nameController.text = widget.product.name;
                          selectedType = widget.product.type;
                          priceController.text = widget.product.price.toString();
                          purchaseLinkController.text = widget.product.purchaseLink;
                        });
                      },
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : _updateProduct,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('儲存'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}