import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/profile/providers/providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../settings/presentation/pages/settings_page.dart';
import '../dialogs/upload_wardrobe_item_dialog.dart';
import '../mappers/category_display_mapper.dart';
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

    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);

    final isLoading = useState(false);
    final selectedCategory = useState<WardrobeCategory?>(null);
    final categoryScrollController = useScrollController();

    // Build category list with display names for UI
    final wardrobeCategories = useMemoized(() {
      return CategoryDisplay.allWithDisplayNames;
    }, []);

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

      final useCase = ref.read(deleteWardrobeItemUseCaseProvider);
      final result = await useCase(item);

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(wardrobeItemsProvider);
      } else {
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
          builder: (final context) => UploadWardrobeItemDialog(image: image),
        );
      }
    }

    Widget buildCategoryChip(final String displayName, final bool isSelected) {
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
              // Find the category enum from display name
              if (displayName == '全部') {
                selectedCategory.value = null;
              } else {
                final categoryEntry = wardrobeCategories.firstWhere(
                  (final entry) => entry.value == displayName,
                );
                selectedCategory.value = categoryEntry.key;
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Center(
                child: Text(
                  displayName,
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
          itemCount: wardrobeCategories.length + 1, // +1 for "全部"
          itemBuilder: (final context, final index) {
            if (index == 0) {
              // "全部" category
              final isSelected = selectedCategory.value == null;
              return buildCategoryChip('全部', isSelected);
            }
            final categoryEntry = wardrobeCategories[index - 1];
            final isSelected = selectedCategory.value == categoryEntry.key;
            return buildCategoryChip(categoryEntry.value, isSelected);
          },
        ),
      );
    }

    Widget buildEmptyState() {
      return LayoutBuilder(
        builder: (final context, final constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 50,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '此衣櫃沒有衣物',
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
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
                      onRefresh: () async => ref.invalidate(wardrobeItemsProvider),
                      child: wardrobeItemsAsync.when(
                        data: (final wardrobeItems) {
                          final filteredWardrobeItems = selectedCategory.value == null
                              ? wardrobeItems
                              : wardrobeItems
                                    .where(
                                      (final item) =>
                                          item.category == selectedCategory.value,
                                    )
                                    .toList();

                          if (filteredWardrobeItems.isEmpty) {
                            return buildEmptyState();
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
                              itemCount: filteredWardrobeItems.length,
                              itemBuilder: (final context, final index) {
                                return WardrobeItemCard(
                                  item: filteredWardrobeItems[index],
                                  onDelete: () =>
                                      showDeleteDialog(filteredWardrobeItems[index]),
                                );
                              },
                            );
                          }
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (final error, final stack) => ErrorView(
                          onRetry: () => ref.invalidate(wardrobeItemsProvider),
                        ),
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
