import 'package:flutter/material.dart';
import 'dart:io';

import '../ImagePickerHelper.dart';


class ClosetPage extends StatefulWidget {
  final String username;

  const ClosetPage({super.key, required this.username});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  List<String> categories = ['全部', '上衣', '褲子', '裙子'];
  String selectedCategory = '全部';

  List<Map<String, dynamic>> clothes = [
    {
      'image': 'https://via.placeholder.com/100',
      'category': '上衣',
      'color': '米白',
      'size': 'M',
    },
    {
      'image': 'https://via.placeholder.com/100',
      'category': '褲子',
      'color': '深藍',
      'size': 'S',
    },
    // 可持續新增
  ];

  void _addCategory() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增分類'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '輸入分類名稱'),
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text, // 支援中英文
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newCategory = controller.text.trim();
                if (newCategory.isNotEmpty) {
                  setState(() => categories.add(newCategory));
                }
                Navigator.pop(context);
              },
              child: const Text('新增'),
            ),
          ],
        );
      },
    );
  }


  void _showAddClothingDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController colorController = TextEditingController();
    final TextEditingController sizeController = TextEditingController();
    String? selectedCategory;
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增衣物'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 圖片選擇（使用 ImagePickerHelper）
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
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7CCC8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedImage == null
                          ? const Center(
                        child: Text('點擊選擇圖片',
                            style: TextStyle(color: Color(0xFF5D4037))),
                      )
                          : Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 12),


                  // 分類選擇
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '分類'),
                    items: categories
                        .where((cat) => cat != '全部')
                        .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ))
                        .toList(),
                    validator: (value) =>
                    value == null ? '請選擇分類' : null,
                    onChanged: (value) => selectedCategory = value,
                  ),

                  const SizedBox(height: 12),

                  // 顏色輸入
                  TextFormField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: '顏色'),
                    validator: (value) =>
                    value == null || value.isEmpty ? '請輸入顏色' : null,
                  ),

                  const SizedBox(height: 12),

                  // 尺寸輸入
                  TextFormField(
                    controller: sizeController,
                    decoration: const InputDecoration(labelText: '尺寸'),
                    validator: (value) =>
                    value == null || value.isEmpty ? '請輸入尺寸' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate() && selectedImage != null) {
                  setState(() {
                    clothes.add({
                      'image': selectedImage!.path,
                      'category': selectedCategory,
                      'color': colorController.text.trim(),
                      'size': sizeController.text.trim(),
                    });
                  });
                  Navigator.pop(context);
                } else if (selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請選擇圖片')),
                  );
                }
              },
              child: const Text('新增'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            '${widget.username} 的衣櫃',
            style: const TextStyle(color: Color(0xFF5D4037)), // 深棕色字體
          ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)), // 返回鍵顏色
      ),
        body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第二層：分類選單
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: [
                ...categories.map((cat) => ChoiceChip(
                  label: Text(
                    cat,
                    style: const TextStyle(color: Color(0xFF5D4037)), // 深棕色
                  ),
                  selected: selectedCategory == cat,
                  selectedColor: const Color(0xFFD7CCC8), // 淺棕色
                  backgroundColor: Colors.white,
                  onSelected: (_) {
                    setState(() => selectedCategory = cat);
                  },
                )),
                ActionChip(
                  label: const Icon(Icons.add, color: Color(0xFF5D4037)),
                  backgroundColor: Colors.white,
                  onPressed: _addCategory,
                ),
              ],
            ),
          ),

          // 第三層：衣物卡片區塊
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), // 禁止 GridView 自己滾動
                  shrinkWrap: true, // 讓 GridView 高度由內容決定
                  itemCount: clothes
                      .where((item) =>
                  selectedCategory == '全部' ||
                      item['category'] == selectedCategory)
                      .length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = clothes
                        .where((item) =>
                    selectedCategory == '全部' ||
                        item['category'] == selectedCategory)
                        .toList()[index];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: 點擊衣物圖片後的動作（例如預覽或編輯）
                                  print('點擊了衣物：${item['category']}');
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(item['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('分類：${item['category']}',
                                style: const TextStyle(color: Color(0xFF5D4037))),
                            Text('顏色：${item['color']}',
                                style: const TextStyle(color: Color(0xFF5D4037))),
                            Text('尺寸：${item['size']}',
                                style: const TextStyle(color: Color(0xFF5D4037))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      // 右下角圓形加號按鈕
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClothingDialog,
        backgroundColor: const Color(0xFF5D4037), // 深棕色
        child: const Icon(Icons.add, color: Colors.white), // 白色加號
      ),

    );
  }
}