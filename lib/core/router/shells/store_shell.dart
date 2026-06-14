import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';

class StoreTabDestination {
  const StoreTabDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const storeTabDestinations = [
  StoreTabDestination(label: '商品', icon: Icons.storefront_outlined),
  StoreTabDestination(label: '我的', icon: Icons.person_outline),
];

class StoreShell extends HookConsumerWidget {
  const StoreShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final lastTabTapTime = useState<DateTime?>(null);

    Future<void> switchToPersonal() async {
      await ref.read(setLastLoginTypeUseCaseProvider).call(UserType.personal);
      if (!context.mounted) return;
      context.go(AppRoutes.personalHome);
    }

    void onItemTapped(final int index) {
      const doubleTapThreshold = Duration(milliseconds: 400);
      final lastTabIndex = storeTabDestinations.length - 1;

      if (index == lastTabIndex) {
        final now = DateTime.now();
        final last = lastTabTapTime.value;
        if (last != null && now.difference(last) < doubleTapThreshold) {
          lastTabTapTime.value = null;
          switchToPersonal();
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
          items: storeTabDestinations
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

Object _adaptiveIcon(final StoreTabDestination destination) {
  if (PlatformInfo.isIOS26OrHigher()) {
    return switch (destination.label) {
      '商品' => 'bag',
      '我的' => 'person',
      _ => 'circle',
    };
  }

  if (PlatformInfo.isIOS) {
    return switch (destination.label) {
      '商品' => CupertinoIcons.bag,
      '我的' => CupertinoIcons.person,
      _ => CupertinoIcons.circle,
    };
  }

  return destination.icon;
}
