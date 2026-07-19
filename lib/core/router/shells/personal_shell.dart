import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

class PersonalTabDestination {
  const PersonalTabDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const personalTabDestinations = [
  PersonalTabDestination(label: '首頁', icon: Icons.home_outlined),
  PersonalTabDestination(label: '試衣間', icon: Icons.shopping_cart_outlined),
  PersonalTabDestination(label: '聊天', icon: Icons.chat_outlined),
  PersonalTabDestination(label: '衣櫃', icon: Icons.checkroom_outlined),
  PersonalTabDestination(label: '我的', icon: Icons.person_outline),
];

class PersonalShell extends HookConsumerWidget {
  const PersonalShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final coordinator = ref.read(tryonCoordinatorProvider);

    useEffect(() {
      void navigateToHome() => navigationShell.goBranch(0);
      coordinator.bindNavigateToHome(navigateToHome);
      return () => coordinator.unbindNavigateToHome(navigateToHome);
    }, [coordinator, navigationShell]);

    final lastTabTapTime = useState<DateTime?>(null);

    Future<void> switchToStore() async {
      await ref.read(setLastLoginTypeUseCaseProvider).call(UserType.store);
      if (!context.mounted) return;
      context.go(AppRoutes.dashboardAccount);
    }

    void onItemTapped(final int index) {
      const doubleTapThreshold = Duration(milliseconds: 400);
      final lastTabIndex = personalTabDestinations.length - 1;

      if (index == lastTabIndex) {
        final now = DateTime.now();
        final last = lastTabTapTime.value;
        if (last != null && now.difference(last) < doubleTapThreshold) {
          lastTabTapTime.value = null;
          switchToStore();
          return;
        }
        lastTabTapTime.value = now;
      }

      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0)),
      child: AdaptiveScaffold(
        minimizeBehavior: TabBarMinimizeBehavior.never,
        body: MediaQuery(data: mediaQuery, child: navigationShell),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onTap: onItemTapped,
          useNativeBottomBar: true,
          items: personalTabDestinations
              .map(
                (final destination) => AdaptiveNavigationDestination(
                  icon: _adaptiveIcon(destination),
                  label: destination.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

Object _adaptiveIcon(final PersonalTabDestination destination) {
  if (PlatformInfo.isIOS26OrHigher()) {
    return switch (destination.label) {
      '首頁' => 'house',
      '試衣間' => 'cart',
      '聊天' => 'message',
      '衣櫃' => 'hanger',
      '我的' => 'person',
      _ => 'circle',
    };
  }

  if (PlatformInfo.isIOS) {
    return switch (destination.label) {
      '首頁' => CupertinoIcons.house,
      '試衣間' => CupertinoIcons.cart,
      '聊天' => CupertinoIcons.chat_bubble,
      '衣櫃' => CupertinoIcons.collections,
      '我的' => CupertinoIcons.person,
      _ => CupertinoIcons.circle,
    };
  }

  return destination.icon;
}
