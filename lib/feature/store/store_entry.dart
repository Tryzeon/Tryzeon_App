import 'package:flutter/material.dart';
import 'home/settings/data/profile_service.dart';
import 'home/product/persentation/product_page.dart';
import 'onboarding/persentation/pages/store_onboarding_page.dart';
import 'package:tryzeon/shared/services/auth_service.dart';

/// 店家入口 - 負責判斷是否需要 onboarding
class StoreEntry extends StatefulWidget {
  const StoreEntry({super.key});

  @override
  State<StoreEntry> createState() => _StoreEntryState();
}

class _StoreEntryState extends State<StoreEntry> {
  bool _isChecking = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkStoreInfo();
    
    AuthService.saveLastLoginType(UserType.store);
  }

  Future<void> _checkStoreInfo() async {
    final storeData = await StoreProfileService.getStore();
    setState(() {
      _needsOnboarding = storeData == null;
      _isChecking = false;
    });
  }

  void _onOnboardingComplete() {
    setState(() {
      _needsOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsOnboarding) {
      return PopScope(
        canPop: false, // 防止返回
        child: StoreOnboardingPage(
          onComplete: _onOnboardingComplete,
        ),
      );
    }

    return const StoreHomePage();
  }
}
