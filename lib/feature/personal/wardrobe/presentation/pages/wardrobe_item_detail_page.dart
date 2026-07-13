import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_fab.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/actions/trigger_wardrobe_item_tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../sheets/wardrobe_tag_editor_sheet.dart';

class WardrobeItemDetailPage extends HookConsumerWidget {
  const WardrobeItemDetailPage({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);

    return wardrobeItemsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (final error, final stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error.displayMessage(context),
          onRetry: () => ref.invalidate(wardrobeItemsProvider),
        ),
      ),
      data: (final items) {
        final item = items.where((final i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('找不到衣物', style: textTheme.titleMedium)),
          );
        }
        return _WardrobeItemDetailContent(
          item: item,
          colorScheme: colorScheme,
          textTheme: textTheme,
        );
      },
    );
  }
}

class _WardrobeItemDetailContent extends ConsumerWidget {
  const _WardrobeItemDetailContent({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
  });

  final WardrobeItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final imageFileAsync = ref.watch(wardrobeItemImageProvider(item.imagePath));

    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final hasVideoAccess = capabilitiesAsync.maybeWhen(
      data: (final capabilities) => capabilities.hasVideoAccess,
      orElse: () => false,
    );

    Future<void> handleDelete() async {
      final confirmResult = await showAppOkCancelDialog(
        context: context,
        title: '刪除衣物',
        message: '你確定要刪除這件衣物嗎？',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (confirmResult != OkCancelResult.ok || !context.mounted) return;

      final deleteWardrobeItemUseCase = ref.read(deleteWardrobeItemUseCaseProvider);
      final result = await deleteWardrobeItemUseCase(item);

      if (!context.mounted) return;

      if (result.isSuccess) {
        ref.invalidate(wardrobeItemsProvider);
        context.pop();
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
    }

    Future<String?> handleSaveTags(final List<String> tags) async {
      final updateWardrobeItemTagsUseCase = ref.read(
        updateWardrobeItemTagsUseCaseProvider,
      );
      final result = await updateWardrobeItemTagsUseCase(item: item, tags: tags);

      if (!context.mounted) return null;

      if (result.isFailure) {
        return result.getError()!.displayMessage(context);
      }

      ref.invalidate(wardrobeItemsProvider);
      return null;
    }

    Future<void> handleEditTags() async {
      await WardrobeTagEditorSheet.show(
        context: context,
        initialTags: item.tags,
        onSave: handleSaveTags,
      );
    }

    Widget buildTagChips() {
      if (item.tags.isEmpty) {
        return Text(
          '尚無標籤',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        );
      }

      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: item.tags.map((final tag) {
          return Chip(label: Text('#$tag'));
        }).toList(),
      );
    }

    final createdAt = item.createdAt;
    final dateStr =
        '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} 加入';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer.withValues(
                    alpha: AppOpacity.overlay,
                  ),
                  foregroundColor: colorScheme.onSurface,
                ),
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer.withValues(
                      alpha: AppOpacity.overlay,
                    ),
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: handleDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  imageFileAsync.when(
                    data: (final file) => Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (final context, final error, final stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerLow,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: AppSpacing.xxl,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (final error, final stack) => Container(
                      color: colorScheme.surfaceContainerLow,
                      child: Center(
                        child: ErrorView(
                          isCompact: true,
                          onRetry: () =>
                              ref.refresh(wardrobeItemImageProvider(item.imagePath)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: TryOnFab(
                      onTap: () => triggerWardrobeItemTryOn(
                        context,
                        ref,
                        item,
                        hasVideoAccess: hasVideoAccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(item.category.displayName)),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Text(
                        '標籤',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '編輯標籤',
                        onPressed: handleEditTags,
                        icon: const Icon(Icons.edit_outlined),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  buildTagChips(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
