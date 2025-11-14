import 'package:flutter/material.dart';
import 'dart:io';
import 'settings/data/profile_service.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'wardrobe/data/wardrobe_service.dart';
import 'wardrobe/persentation/dialogs/upload_clothing_dialog.dart';
import 'wardrobe/persentation/widgets/clothing_card.dart';
import 'settings/settings_page.dart';


class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  String username = '';
  List<String> wardrobeCategories = [];
  String selectedCategory = '全部';
  List<Clothing> clothing = [];
  final ScrollController _categoryScrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalData();
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalData({bool forceRefresh = false}) async {
    await _loadUsername(forceRefresh: forceRefresh);
    await _loadWardrobeItems(forceRefresh: forceRefresh);
  }

  Future<void> _loadUsername({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await UserProfileService.getUserProfile(forceRefresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      if (result.isSuccess) {
        username = result.data!.name;
        _isLoading = false;
      }
    });
  }

  Future<void> _loadWardrobeItems({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final categories = WardrobeService.getWardrobeTypesList();
    final result = await WardrobeService.getClothing(forceRefresh: forceRefresh);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      setState(() {
        clothing = result.data!;
        wardrobeCategories = ['全部', ...categories];
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '載入衣櫃項目失敗',
        type: NotificationType.error,
      );
    }
  }

  void _showDeleteDialog(Clothing item) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: '刪除衣物',
      content: '你確定要刪除這件衣物嗎？',
      confirmText: '刪除',
    );

    if (confirmed != true || !mounted) return;

    final result = await WardrobeService.deleteClothing(item);
    if (!mounted) return;

    if (result.isSuccess) {
      await _loadWardrobeItems();
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage ?? '刪除失敗，請稍後再試',
        type: NotificationType.error,
      );
    }
  }

  void _showUploadDialog() async {
    final File? image = await ImagePickerHelper.pickImage(context);

    if (image != null && mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => UploadClothingDialog(
          image: image,
          categories: WardrobeService.getWardrobeTypesList(),
        ),
      );

      if (result == true) {
        await _loadWardrobeItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題區
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 設定按鈕和使用者名稱
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 使用者名稱
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '您好, $username',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // 設定按鈕
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final hasChanges = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PersonalSettingsPage(),
                                  ),
                                );
                                if (hasChanges == true) {
                                  await _loadPersonalData();
                                }
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Icon(
                                Icons.settings_rounded,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 我的衣櫃標題
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.checkroom_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '我的衣櫃',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 分類選單
              _buildCategoryBar(),

              // 衣櫃內容
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadPersonalData(forceRefresh: true),
                  child: _buildClothingGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _showUploadDialog,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
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
        itemCount: wardrobeCategories.length,
        itemBuilder: (context, index) {
          final category = wardrobeCategories[index];
          final isSelected = selectedCategory == category;
          return _buildCategoryChip(category, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              )
            : null,
        color: isSelected ? null : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Center(
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClothingGrid() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final filteredClothing = selectedCategory == '全部'
        ? clothing
        : clothing.where((item) => item.category == selectedCategory).toList();

    if (filteredClothing.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom_rounded,
                size: 50,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              selectedCategory == '全部' ? '衣櫃是空的' : '此類別沒有衣物',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '點擊右下角按鈕新增衣物',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: filteredClothing.length,
        itemBuilder: (context, index) {
          return ClothingCard(
            item: filteredClothing[index],
            onDelete: () => _showDeleteDialog(filteredClothing[index]),
          );
        },
      );
    }
  }
}

