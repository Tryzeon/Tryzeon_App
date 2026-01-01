import 'package:flutter/material.dart';
import 'package:tryzeon/feature/auth/data/auth_service.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../home/presentation/pages/home_page.dart';
import '../home/presentation/pages/settings/data/profile_service.dart';
import '../onboarding/presentation/pages/store_onboarding_page.dart';

/// 店家入口 - 負責判斷是否需要 onboarding
class StoreEntry extends StatefulWidget {
  const StoreEntry({super.key});

  @override
  State<StoreEntry> createState() => _StoreEntryState();
}

class _StoreEntryState extends State<StoreEntry> {
  bool _isChecking = true;
  bool _needsOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkStoreInfo();

    AuthService.setLastLoginType(UserType.store);
  }

  Future<void> _checkStoreInfo() async {
    setState(() {
      _isChecking = true;
    });

    final state = await StoreProfileService.storeProfileQuery().fetch();
    if (!mounted) return;

    if (state.error != null) {
      TopNotification.show(
        context,
        message: state.error.toString(),
        type: NotificationType.error,
      );
    }

    setState(() {
      _needsOnboarding = (state.data == null);
      _isChecking = false;
    });
  }

  @override
  Widget build(final BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsOnboarding) {
      return PopScope(
        canPop: false,
        child: StoreOnboardingPage(onRefresh: _checkStoreInfo),
      );
    } else {
      return const StoreHomePage();
    }
  }
}
