import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/store_account_header.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/unlist_reminder_section.dart';
import 'package:tryzeon/feature/store/analytics/presentation/widgets/month_filter_widget.dart';
import 'package:tryzeon/feature/store/analytics/presentation/widgets/store_traffic_dashboard.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/store_add_product_fab.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

class StoreAccountPage extends HookConsumerWidget {
  const StoreAccountPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final profile = ref.watch(storeProfileProvider).value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(storeProfileProvider.notifier).refresh(),
              ref.read(productAnalyticsSummariesProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              StoreAccountHeader(profile: profile),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: Text('數據儀表板', style: textTheme.headlineMedium)),
                    const MonthFilterWidget(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: StoreTrafficDashboard(),
              ),
              const UnlistReminderSection(),
              SizedBox(
                height: PlatformInfo.isIOS26OrHigher()
                    ? AppSpacing.iosTabBarHeight
                    : AppSpacing.md,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const StoreAddProductFab(),
    );
  }
}
