// lib/feature/personal/account/presentation/pages/account_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/nav_row.dart';
import 'package:tryzeon/core/presentation/widgets/section_label.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/settings/providers/settings_controller.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/widgets/subscription_usage_card.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';

class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  /// Re-fetches everything this page displays. Nothing here rebuilds on its own:
  /// the usage cache is `keepAlive`, and the two subscription providers are only
  /// invalidated by the purchase/restore flows — so pull-to-refresh is the only
  /// way to pick up a day rollover or an entitlement changed on another device.
  ///
  /// All four start together so the indicator spins for the slowest, not the sum.
  Future<void> _refresh(final WidgetRef ref) async {
    await ref.read(invalidateEntitlementCacheUseCaseProvider)();

    ref
      ..invalidate(dailyUsageTodayProvider)
      ..invalidate(appSubscriptionEntitlementProvider)
      ..invalidate(subscriptionCapabilitiesProvider);

    await Future.wait([
      // Guards its own failures internally.
      ref.read(userProfileProvider.notifier).refresh(),
      _settle(ref.read(dailyUsageTodayProvider.future)),
      _settle(ref.read(appSubscriptionEntitlementProvider.future)),
      _settle(ref.read(subscriptionCapabilitiesProvider.future)),
    ]);
  }

  /// Awaits [future] without letting it reject: each provider's own `AsyncError`
  /// already renders in the section that watches it, and an unhandled rejection
  /// would leave [RefreshIndicator] spinning.
  Future<void> _settle(final Future<Object?> future) async {
    try {
      await future;
    } catch (e, stackTrace) {
      AppLogger.warning('Account pull-to-refresh: a source failed', e, stackTrace);
    }
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);

    ref.listen(settingsControllerProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(context, message: next.error.displayMessage(context));
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            edgeOffset: MediaQuery.of(context).padding.top,
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppSpacing.md),
                        _ProfileHeader(),
                        SizedBox(height: AppSpacing.lg),
                        Divider(),
                        SectionLabel('訂閱方案'),
                        _SubscriptionSection(),
                        SectionLabel('身形'),
                        _BodyMeasurementsRow(),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MY ACCOUNT',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('我的帳戶', style: textTheme.headlineMedium),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '設定',
                onPressed: () => context.push(AppRoutes.personalSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends HookConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final profileAsync = ref.watch(userProfileProvider);
    final avatarFileAsync = ref.watch(avatarFileProvider);

    final profile = profileAsync.value;
    final avatarFile = avatarFileAsync.value;

    final isProfileLoading = profileAsync.isLoading && !profileAsync.hasValue;
    final hasProfileError = profileAsync.hasError;
    final isAvatarLoading = avatarFileAsync.isLoading && !avatarFileAsync.hasValue;

    Widget buildAvatar() {
      if (isProfileLoading || isAvatarLoading) {
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
        );
      }
      if (hasProfileError || profile == null) {
        return Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant);
      }
      if (avatarFile != null) {
        return SizedBox.expand(child: Image.file(avatarFile, fit: BoxFit.cover));
      }
      return Icon(Icons.person, color: colorScheme.onSurfaceVariant);
    }

    Widget buildInfo() {
      if (isProfileLoading) {
        return Text(
          '載入中…',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
      if (hasProfileError) {
        return Text('載入個人資料失敗', style: theme.textTheme.titleMedium);
      }
      if (profile == null) {
        return Text('尚未建立個人資料', style: theme.textTheme.titleMedium);
      }
      
      final email = profile.email;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(profile.name, style: theme.textTheme.titleMedium),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: buildAvatar(),
        ),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(child: buildInfo()),
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.personalSettingsProfile),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.smMd,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: theme.textTheme.labelMedium,
          ),
          child: const Text('編輯'),
        ),
      ],
    );
  }
}

class _SubscriptionSection extends HookConsumerWidget {
  const _SubscriptionSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entitlementAsync = ref.watch(appSubscriptionEntitlementProvider);
    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final usageAsync = ref.watch(dailyUsageTodayProvider);

    void openSubscription() => context.push(AppRoutes.personalSubscription);
    // Entitlement is structural (defines plan identity); without it the card
    // has no meaning. Capabilities and usage degrade per-stat inside the card.
    final entitlement = entitlementAsync.value;
    if (entitlement == null) {
      return entitlementAsync.hasError
          ? _SubscriptionErrorCard(onTap: openSubscription)
          : const SubscriptionUsageCardSkeleton();
    }

    return SubscriptionUsageCard(
      entitlement: entitlement,
      formattedRenewalLine: formatRenewalLine(entitlement),
      dailyTryonUsed: usageAsync.value?.tryonCount,
      dailyTryonLimit: capabilitiesAsync.value?.dailyTryonLimit,
      onTap: openSubscription,
    );
  }
}

class _SubscriptionErrorCard extends StatelessWidget {
  const _SubscriptionErrorCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '很抱歉，無法載入訂閱資訊，請稍後再試！',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyMeasurementsRow extends HookConsumerWidget {
  const _BodyMeasurementsRow();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    final String? trailing;
    if (profileAsync.isLoading && !profileAsync.hasValue) {
      trailing = null;
    } else {
      final filled = profileAsync.value?.measurements.filledCount ?? 0;
      final total = BodyMeasurements.fieldCount;
      if (filled == 0) {
        trailing = '未填寫';
      } else if (filled == total) {
        trailing = '已完成';
      } else {
        trailing = '$filled / $total 已填寫';
      }
    }

    return NavRow(
      icon: Icons.straighten_outlined,
      title: '身形資料',
      trailingValue: trailing,
      isFirst: true,
      onTap: () => context.push(AppRoutes.personalSettingsBodyMeasurements),
    );
  }
}
