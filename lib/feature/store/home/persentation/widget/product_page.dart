import 'package:flutter/material.dart';
import 'dart:io';

import 'package:tryzeon/shared/image_picker_helper.dart';
import '../../data/product_service.dart';


class ProductSPage extends StatefulWidget {
  const ProductSPage({super.key});

  @override
  State<ProductSPage> createState() => _ProductSPageState();
}

class _ProductSPageState extends State<ProductSPage> {
  final TextEditingController typeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  File? selectedImage;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增商品'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: () async {
                final image = await ImagePickerHelper.pickImage(context);
                if (image != null) {
                  setState(() {
                    selectedImage = image;
                  });
                }
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7CCC8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedImage == null
                    ? const Center(child: Text('點擊選擇圖片'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedImage!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '商品名稱'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: '衣服種類'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: '價格'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (selectedImage != null && 
                    nameController.text.isNotEmpty && 
                    typeController.text.isNotEmpty && 
                    priceController.text.isNotEmpty) {
                  setState(() {
                    isLoading = true;
                  });

                  final price = double.tryParse(priceController.text);
                  if (price == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請輸入有效的價格')),
                    );
                    setState(() {
                      isLoading = false;
                    });
                    return;
                  }

                  final success = await ProductService.createProduct(
                    name: nameController.text,
                    type: typeController.text,
                    price: price,
                    imageFile: selectedImage,
                  );

                  setState(() {
                    isLoading = false;
                  });

                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('商品新增成功')),
                      );
                      Navigator.pop(context);
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('商品新增失敗，請稍後再試')),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請填寫完整資料')),
                  );
                }
              },
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('新增商品'),
            ),
          ],
        ),
      ),
    );
  }
}