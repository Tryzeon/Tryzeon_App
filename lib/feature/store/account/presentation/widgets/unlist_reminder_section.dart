import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/state/unlist_reminder.dart';
import 'package:tryzeon/feature/store/account/providers/unlist_reminder_providers.dart';
import 'package:tryzeon/feature/store/products/presentation/actions/toggle_product_status.dart';

/// Products someone clicked through to buy, so the owner can check the stock
/// and unlist what has sold out.
class UnlistReminderSection extends HookConsumerWidget {
  const UnlistReminderSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final remindersAsync = ref.watch(unlistRemindersProvider);

    // Nothing to act on, so the section stays out of the page entirely — its
    // own top spacing included.
    if (remindersAsync.value?.isEmpty ?? false) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _SectionHeader(),
          ),
          const SizedBox(height: AppSpacing.sm),
          remindersAsync.when(
            loading: () => const _LoadingRows(),
            error: (final error, final stackTrace) => const ErrorView(isCompact: true),
            data: (final reminders) => Column(
              children: [
                for (final reminder in reminders) _ReminderRow(reminder: reminder),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('下架提醒', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        // Without this the section reads as nonsense: these are the products
        // selling best, filed under a heading that says to take them down.
        Text(
          '依購買連結點擊次數排序，確認庫存後可下架',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder});

  final UnlistReminder reminder;

  @override
  Widget build(final BuildContext context) {
    final product = reminder.product;

    return ListTile(
      onTap: () => context.push(AppRoutes.dashboardProductDetailPath(product.id)),
      leading: _Thumbnail(
        imageUrl: product.imageUrls.firstOrNull,
        cacheKey: product.imagePaths.firstOrNull,
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ClickCount(clicks: reminder.clicks),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => toggleProductStatus(context, product),
            child: const Text('下架'),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.imageUrl, this.cacheKey});

  final String? imageUrl;
  final String? cacheKey;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        width: AppSpacing.xxl,
        height: AppSpacing.xxl,
        color: colorScheme.surfaceContainerLow,
        child: imageUrl == null
            ? Icon(
                Icons.checkroom_outlined,
                size: AppSpacing.mdLg,
                color: colorScheme.onSurfaceVariant,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                cacheKey: cacheKey,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (final context, final url) =>
                    Container(color: colorScheme.surfaceContainerLow),
                errorWidget: (final context, final url, final error) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}

/// Charcoal like the dashboard figures above, so the two sections read as one
/// page. The metric is named once in the section subtitle, not on every row.
class _ClickCount extends StatelessWidget {
  const _ClickCount({required this.clicks});

  final int clicks;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      clicks.toString(),
      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(final BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            const ListTile(
              leading: _Thumbnail(),
              title: Text('商品名稱'),
              trailing: _ClickCount(clicks: 0),
            ),
        ],
      ),
    );
  }
}
