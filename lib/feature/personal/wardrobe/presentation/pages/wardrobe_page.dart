import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_query_builder.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/profile/providers/providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../settings/presentation/pages/settings_page.dart';
import '../../data/wardrobe_item_model.dart';
import '../../data/wardrobe_service.dart';
import '../dialogs/upload_wardrobe_item_dialog.dart';
import '../widgets/wardrobe_item_card.dart';

class PersonalPage extends HookConsumerWidget {
  const PersonalPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );
    final isLoading = useState(false);
    final selectedCategory = useState('全部');
    final categoryScrollController = useScrollController();

    final wardrobeCategories = useMemoized(() {
      final categories = WardrobeService.getWardrobeTypesList();
      return ['全部', ...categories];
    });

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> showDeleteDialog(final WardrobeItem item) async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '刪除衣物',
        content: '你確定要刪除這件衣物嗎？',
        confirmText: '刪除',
      );

      if (confirmed != true || !context.mounted) return;

      isLoading.value = true;

      final result = await WardrobeService.deleteWardrobeItem(item);

      if (!context.mounted) return;

      isLoading.value = false;

      if (!result.isSuccess) {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    Future<void> showUploadDialog() async {
      final File? image = await ImagePickerHelper.pickImage(context);

      if (image != null && context.mounted) {
        await showDialog<bool>(
          context: context,
          builder: (final context) => UploadWardrobeItemDialog(
            image: image,
            categories: WardrobeService.getWardrobeTypesList(),
          ),
        );
      }
    }

    Widget buildCategoryChip(final String category, final bool isSelected) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [colorScheme.primary, colorScheme.secondary])
              : null,
          color: isSelected ? null : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
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
              selectedCategory.value = category;
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Center(
                child: Text(
                  category,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
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

    Widget buildCategoryBar() {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          controller: categoryScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: wardrobeCategories.length,
          itemBuilder: (final context, final index) {
            final category = wardrobeCategories[index];
            final isSelected = selectedCategory.value == category;
            return buildCategoryChip(category, isSelected);
          },
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surface,
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
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: ShaderMask(
                                  shaderCallback: (final bounds) => LinearGradient(
                                    colors: [colorScheme.primary, colorScheme.secondary],
                                  ).createShader(bounds),
                                  child: Text(
                                    profile != null ? '您好, ${profile.name}' : '您好',
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            // 設定按鈕
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (final context) =>
                                            const PersonalSettingsPage(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: Icon(
                                    Icons.settings_rounded,
                                    color: colorScheme.onSurface,
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
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '我的衣櫃',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 分類選單
                  buildCategoryBar(),

                  // 衣櫃內容
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => WardrobeService.wardrobeItemsQuery().refetch(),
                      child: AppQueryBuilder<List<WardrobeItem>>(
                        query: WardrobeService.wardrobeItemsQuery(),
                        builder: (final context, final wardrobeItem) {
                          final filteredWardrobeItem = selectedCategory.value == '全部'
                              ? wardrobeItem
                              : wardrobeItem
                                    .where(
                                      (final item) =>
                                          item.category == selectedCategory.value,
                                    )
                                    .toList();

                          if (filteredWardrobeItem.isEmpty) {
                            return LayoutBuilder(
                              builder: (final context, final constraints) {
                                return SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.checkroom_rounded,
                                              size: 50,
                                              color: colorScheme.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            selectedCategory.value == '全部'
                                                ? '衣櫃是空的'
                                                : '此類別沒有衣物',
                                            style: textTheme.titleMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '點擊右下角按鈕新增衣物',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount: filteredWardrobeItem.length,
                              itemBuilder: (final context, final index) {
                                return WardrobeItemCard(
                                  item: filteredWardrobeItem[index],
                                  onDelete: () =>
                                      showDeleteDialog(filteredWardrobeItem[index]),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading.value)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: showUploadDialog,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
