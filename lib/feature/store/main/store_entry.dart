import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../home/presentation/pages/home_page.dart';
import '../onboarding/presentation/pages/store_onboarding_page.dart';
import '../settings/data/profile_service.dart';

/// 店家入口 - 負責判斷是否需要 onboarding
class StoreEntry extends HookConsumerWidget {
  const StoreEntry({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isChecking = useState(true);
    final needsOnboarding = useState(true);

    Future<void> checkStoreInfo() async {
      isChecking.value = true;

      final state = await StoreProfileService.storeProfileQuery().fetch();
      if (!context.mounted) return;

      if (state.error != null) {
        TopNotification.show(
          context,
          message: state.error.toString(),
          type: NotificationType.error,
        );
      }

      needsOnboarding.value = (state.data == null);
      isChecking.value = false;
    }

    useEffect(() {
      checkStoreInfo();
      return null;
    }, []);

    if (isChecking.value) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (needsOnboarding.value) {
      return PopScope(
        canPop: false,
        child: StoreOnboardingPage(onRefresh: checkStoreInfo),
      );
    } else {
      return const StoreHomePage();
    }
  }
}
