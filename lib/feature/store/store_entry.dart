import 'package:flutter/material.dart';
import 'package:tryzeon/shared/services/auth_service.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import 'home/presentation/pages/home_page.dart';
import 'home/presentation/pages/settings/data/profile_service.dart';
import 'onboarding/presentation/pages/store_onboarding_page.dart';

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

    AuthService.saveLastLoginType(UserType.store);
  }

  Future<void> _checkStoreInfo() async {
    final result = await StoreProfileService.getStoreProfile(
      forceRefresh: true,
    );
    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    if (result.isSuccess) {
      setState(() {
        _needsOnboarding = false;
      });
    } else {
      if (result.errorMessage == '查無店家資料') return;

      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _needsOnboarding = false;
    });
  }

  @override
  Widget build(final BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsOnboarding) {
      return PopScope(
        canPop: false, // 防止返回
        child: StoreOnboardingPage(
          onComplete: _onOnboardingComplete,
          onRefresh: _checkStoreInfo,
        ),
      );
    }

    return const StoreHomePage();
  }
}
