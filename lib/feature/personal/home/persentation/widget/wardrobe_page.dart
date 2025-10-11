import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/wardrobe_service.dart';
import 'package:tryzeon/shared/component/image_picker_helper.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final List<String> defaultCategories = ['上衣', '褲子', '裙子', '外套', '鞋子', '配件', '其他'];
  List<String> categories = [];
  String selectedCategory = '全部';
  List<ClothingItem> clothingItems = [];
  final ScrollController _categoryScrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    categories = ['全部', ...defaultCategories];
    _loadWardrobeItems();
  }

  Future<void> _loadWardrobeItems() async {
    final items = await WardrobeService.getWardrobeItems();
    if (mounted) {
      setState(() {
        clothingItems = items
            .map((item) => ClothingItem(
                  path: item.path,
                  category: item.category,
                ))
            .toList();
        _isLoading = false;
      });
    }
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
        itemCount: categories.length,
        itemBuilder: (context, index) {
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

  Widget _buildClothingGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(item),
      child: Container(
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
                  File(item.path),
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
      ),
    );
  }

  void _showDeleteDialog(ClothingItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除衣物'),
        content: const Text('確定要刪除這件衣物嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await WardrobeService.deleteWardrobeItem(item.path);
              await _loadWardrobeItems();
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() async {
    final File? image = await ImagePickerHelper.pickImage(context);
    
    if (image != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => UploadClothingDialog(
          image: image,
          categories: categories.where((c) => c != '全部').toList(),
          onUpload: (imageId, category) async {
            setState(() {
              _isLoading = true;
            });
            await _loadWardrobeItems();
          },
        ),
      );
    }
  }
}

class ClothingItem {
  final String path;
  final String category;

  ClothingItem({
    required this.path,
    required this.category,
  });
}

class UploadClothingDialog extends StatefulWidget {
  final File image;
  final List<String> categories;
  final Function(String imagePath, String category) onUpload;

  const UploadClothingDialog({
    super.key,
    required this.image,
    required this.categories,
    required this.onUpload,
  });

  @override
  State<UploadClothingDialog> createState() => _UploadClothingDialogState();
}

class _UploadClothingDialogState extends State<UploadClothingDialog> {
  String? _selectedCategory;
  bool _isUploading = false;

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
            _buildImagePreview(),
            const SizedBox(height: 16),
            _buildCategorySelector(),
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
                  onPressed: _selectedCategory != null && !_isUploading
                      ? () async {
                          setState(() {
                            _isUploading = true;
                          });

                          final result = await WardrobeService.uploadWardrobeItem(
                            widget.image,
                            _selectedCategory!,
                          );

                          if (!context.mounted) return;

                          if (result != null) {
                            widget.onUpload(result['path']!, _selectedCategory!);
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _isUploading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('上傳失敗')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('上傳'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(widget.image, fit: BoxFit.cover),
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

}