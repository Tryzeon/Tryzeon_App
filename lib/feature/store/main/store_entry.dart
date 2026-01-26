import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

import '../home/presentation/pages/home_page.dart';
import '../onboarding/presentation/pages/store_onboarding_page.dart';

/// 店家入口 - 負責判斷是否需要 onboarding
class StoreEntry extends HookConsumerWidget {
  const StoreEntry({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(storeProfileProvider);

    return profileAsync.when(
      data: (final profile) {
        if (profile == null) {
          return const PopScope(canPop: false, child: StoreOnboardingPage());
        }
        return const StoreHomePage();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (final error, final stack) => Scaffold(
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.refresh(storeProfileProvider),
        ),
      ),
    );
  }
}
