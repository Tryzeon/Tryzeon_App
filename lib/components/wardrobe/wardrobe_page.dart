import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final List<String> defaultCategories = ['上衣', '褲子', '裙子', '外套', '鞋子', '配件'];
  List<String> categories = [];
  String selectedCategory = '全部';
  List<ClothingItem> clothingItems = [];
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    categories = ['全部', ...defaultCategories];
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryBar(),
            Expanded(
              child: _buildClothingGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            '我的衣櫃',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _buildAddCategoryButton();
          }
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return _buildCategoryChip(category, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = category;
          });
        },
        selectedColor: Colors.black,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: _showAddCategoryDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.add, size: 20),
        ),
      ),
    );
  }

  Widget _buildClothingGrid() {
    final filteredItems = selectedCategory == '全部'
        ? clothingItems
        : clothingItems.where((item) => item.category == selectedCategory).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedCategory == '全部' ? '衣櫃是空的' : '此類別沒有衣物',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildClothingCard(filteredItems[index]);
      },
    );
  }

  Widget _buildClothingCard(ClothingItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                File(item.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              item.category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => UploadClothingDialog(
        categories: categories.where((c) => c != '全部').toList(),
        onUpload: (imagePath, category) {
          setState(() {
            clothingItems.add(ClothingItem(
              imagePath: imagePath,
              category: category,
            ));
          });
        },
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增類別'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '輸入類別名稱',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  categories.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

class ClothingItem {
  final String imagePath;
  final String category;

  ClothingItem({
    required this.imagePath,
    required this.category,
  });
}

class UploadClothingDialog extends StatefulWidget {
  final List<String> categories;
  final Function(String imagePath, String category) onUpload;

  const UploadClothingDialog({
    super.key,
    required this.categories,
    required this.onUpload,
  });

  @override
  State<UploadClothingDialog> createState() => _UploadClothingDialogState();
}

class _UploadClothingDialogState extends State<UploadClothingDialog> {
  File? _image;
  String? _selectedCategory;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '上傳衣物',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildImagePicker(),
            if (_image != null) ...[
              const SizedBox(height: 16),
              _buildCategorySelector(),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _image != null && _selectedCategory != null
                      ? () {
                          widget.onUpload(_image!.path, _selectedCategory!);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('上傳'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    '點擊選擇照片',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '選擇類別',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              selectedColor: Colors.black,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('從相簿選擇'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _image = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _image = File(image.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}