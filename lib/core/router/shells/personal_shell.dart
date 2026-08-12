import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

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
      final lastTabIndex = PersonalTab.values.length - 1;

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

      final isReselect = index == navigationShell.currentIndex;
      navigationShell.goBranch(index, initialLocation: isReselect);
      if (isReselect) {
        ref
            .read(personalTabReselectSignalProvider.notifier)
            .emit(PersonalTab.values[index]);
      }
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
          items: PersonalTab.values
              .map(
                (final tab) => AdaptiveNavigationDestination(
                  icon: _adaptiveIcon(tab),
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

Object _adaptiveIcon(final PersonalTab tab) {
  if (PlatformInfo.isIOS26OrHigher()) {
    return switch (tab) {
      PersonalTab.home => 'house',
      PersonalTab.shop => 'cart',
      PersonalTab.chat => 'message',
      PersonalTab.wardrobe => 'hanger',
      PersonalTab.account => 'person',
    };
  }

  if (PlatformInfo.isIOS) {
    return switch (tab) {
      PersonalTab.home => CupertinoIcons.house,
      PersonalTab.shop => CupertinoIcons.cart,
      PersonalTab.chat => CupertinoIcons.chat_bubble,
      PersonalTab.wardrobe => CupertinoIcons.collections,
      PersonalTab.account => CupertinoIcons.person,
    };
  }

  return tab.icon;
}
