import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../shared/image_picker_helper.dart';


class ProductSPage extends StatefulWidget {
  final String storeName;

  const ProductSPage({super.key, required this.storeName});

  @override
  State<ProductSPage> createState() => _ProductSPageState();
}

class _ProductSPageState extends State<ProductSPage> {
  final TextEditingController typeController = TextEditingController();
  File? selectedImage;

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
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7CCC8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedImage == null
                    ? const Center(child: Text('點擊選擇圖片'))
                    : Image.file(selectedImage!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: '衣服種類'),
            ),
            const SizedBox(height: 12),
            Text('店家名稱：${widget.storeName}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (selectedImage != null && typeController.text.isNotEmpty) {
                  // TODO: 儲存商品邏輯
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請填寫完整資料')),
                  );
                }
              },
              child: const Text('新增商品'),
            ),
          ],
        ),
      ),
    );
  }
}