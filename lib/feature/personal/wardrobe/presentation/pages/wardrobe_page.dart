import 'dart:io';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../sheets/upload_wardrobe_item_sheet.dart';
import '../widgets/wardrobe_item_card.dart';

class WardrobePage extends HookConsumerWidget {
  const WardrobePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 1. Data Providers
    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);

    // 2. State
    final selectedCategory = useState<WardrobeCategory?>(null);
    final categoryScrollController = useScrollController();

    // 3. Memoized Data
    final wardrobeCategories = useMemoized(() {
      return CategoryDisplay.allWithDisplayNames;
    }, []);

    // 4. Theme
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // 5. Actions
    Future<void> showUploadSheet() async {
      final File? image = await ImagePickerHelper.pickImage(context);

      if (image != null && context.mounted) {
        final uploadedCategory = await showModalBottomSheet<WardrobeCategory>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (final context) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: UploadWardrobeItemSheet(image: image),
          ),
        );

        if (uploadedCategory != null) {
          if (selectedCategory.value != null) {
            selectedCategory.value = uploadedCategory;
          }
        }
      }
    }

    // 6. Widget Helpers
    Widget buildCategoryChip(final String displayName, final bool isSelected) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(displayName),
          selected: isSelected,
          onSelected: (final selected) {
            if (displayName == '全部') {
              selectedCategory.value = null;
            } else {
              final categoryEntry = wardrobeCategories.firstWhere(
                (final entry) => entry.value == displayName,
              );
              selectedCategory.value = categoryEntry.key;
            }
          },
        ),
      );
    }

    Widget buildCategoryBar() {
      return Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListView.builder(
          controller: categoryScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: wardrobeCategories.length + 1,
          itemBuilder: (final context, final index) {
            if (index == 0) {
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
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: AppSpacing.xxl,
                        color: colorScheme.primary.withValues(alpha: AppOpacity.overlay),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('此分類沒有衣物', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '點擊右下角 + 上傳第一件衣服',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

    // Determine the count for the header
    final totalCount = wardrobeItemsAsync.value?.length ?? 0;

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: PlatformInfo.isIOS26OrHigher() ? AppSpacing.iosTabBarHeight : 0.0,
        ),
        child: FloatingActionButton(
          onPressed: showUploadSheet,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Layer (Typography driven)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY WARDROBE',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('我的衣櫃', style: textTheme.headlineMedium),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                        child: Text(
                          '$totalCount 件衣物',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category Bar
            buildCategoryBar(),

            // Grid Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => refreshWardrobeItems(ref),
                child: wardrobeItemsAsync.when(
                  skipLoadingOnReload: true,
                  skipError: true,
                  data: (final wardrobeItems) {
                    final filtered = selectedCategory.value == null
                        ? wardrobeItems
                        : wardrobeItems
                              .where((final i) => i.category == selectedCategory.value)
                              .toList();

                    if (filtered.isEmpty) return buildEmptyState();

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        MediaQuery.of(context).padding.bottom +
                            90 + // FAB
                            (PlatformInfo.isIOS26OrHigher()
                                ? AppSpacing.iosTabBarHeight
                                : 0),
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (final context, final index) {
                        return WardrobeItemCard(item: filtered[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (final error, final stack) => ErrorView(
                    message: error.displayMessage(context),
                    onRetry: () => ref.invalidate(wardrobeItemsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
