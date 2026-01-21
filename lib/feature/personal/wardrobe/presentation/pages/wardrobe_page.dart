import 'dart:io';
import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
    // 1. Data Providers
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );
    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);

    // 2. State
    final isLoading = useState(false);
    final selectedCategory = useState<WardrobeCategory?>(null);
    final categoryScrollController = useScrollController();

    // 3. Memoized Data
    final wardrobeCategories = useMemoized(() {
      return CategoryDisplay.allWithDisplayNames;
    }, []);

    // 4. Theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 5. Actions
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

    // 6. Widget Helpers (Glassmorphism Style)
    Widget buildGlassElement({
      required final Widget child,
      final VoidCallback? onTap,
      final EdgeInsetsGeometry padding = EdgeInsets.zero,
      final double borderRadius = 30,
      final Color? color,
    }) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: color ?? colorScheme.surface.withValues(alpha: 0.2),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    Widget buildCategoryChip(final String displayName, final bool isSelected) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: buildGlassElement(
          borderRadius: 20,
          color: isSelected
              ? colorScheme.onSurface.withValues(alpha: 0.8)
              : colorScheme.surface.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () {
            if (displayName == '全部') {
              selectedCategory.value = null;
            } else {
              final categoryEntry = wardrobeCategories.firstWhere(
                (final entry) => entry.value == displayName,
              );
              selectedCategory.value = categoryEntry.key;
            }
          },
          child: Text(
            displayName,
            style: textTheme.bodyMedium?.copyWith(
              color: isSelected ? colorScheme.surface : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    Widget buildCategoryBar() {
      return Container(
        height: 48,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.builder(
          controller: categoryScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '此衣櫃沒有衣物',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
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

    Widget buildAddButton() {
      return buildGlassElement(
        onTap: showUploadDialog,
        // 使用 primary color (黑色)
        color: colorScheme.primary.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              '新增衣服',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Layer
          Container(color: colorScheme.surface),

          // 2. Main Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Spacer for Header
                const SizedBox(height: 80),

                // Category Bar
                buildCategoryBar(),

                // Grid Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => refreshWardrobeItems(ref),
                    child: wardrobeItemsAsync.when(
                      data: (final wardrobeItems) {
                        final filtered = selectedCategory.value == null
                            ? wardrobeItems
                            : wardrobeItems
                                  .where(
                                    (final i) => i.category == selectedCategory.value,
                                  )
                                  .toList();

                        if (filtered.isEmpty) return buildEmptyState();

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (final context, final index) {
                            return WardrobeItemCard(
                              item: filtered[index],
                              onDelete: () => showDeleteDialog(filtered[index]),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (final error, final __) => ErrorView(
                        message: error.toString(),
                        onRetry: () => ref.refresh(wardrobeItemsProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Header Layer (Title & Settings)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '我的衣櫃',
                          style: textTheme.displaySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (profile != null)
                          Text(
                            '你好，${profile.name}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),

                    // Settings Button
                    buildGlassElement(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 30,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (final context) => const PersonalSettingsPage(),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.settings_rounded,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Floating Action Button
          Positioned(
            bottom:
                MediaQuery.of(context).padding.bottom +
                30 +
                (PlatformInfo.isIOS26OrHigher() ? 50 : 0),
            right: 24,
            child: buildAddButton(),
          ),

          // 5. Loading Overlay
          if (isLoading.value)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
